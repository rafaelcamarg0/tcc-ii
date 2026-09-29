-- R01: frequencia de saidas por conta em uma janela temporal.
-- Os parametros iniciais sao experimentais, nao limites legais ou institucionais.

CREATE OR REPLACE PROCEDURE tcc_pld.executar_r01(
    p_identificador_base text,
    p_quantidade_minima integer DEFAULT 5,
    p_janela interval DEFAULT interval '10 minutes',
    p_versao integer DEFAULT 1
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_execucao_id bigint;
    v_base_id bigint;
    v_parametros jsonb;
    v_erro_codigo text;
    v_erro_mensagem text;
BEGIN
    IF p_identificador_base IS NULL OR btrim(p_identificador_base) = '' THEN
        RAISE EXCEPTION 'O identificador da base e obrigatorio';
    END IF;
    IF p_quantidade_minima < 2 THEN
        RAISE EXCEPTION 'A quantidade minima deve ser maior ou igual a 2';
    END IF;
    IF p_janela <= interval '0 seconds' THEN
        RAISE EXCEPTION 'A janela deve ser positiva';
    END IF;
    IF p_versao < 1 THEN
        RAISE EXCEPTION 'A versao deve ser positiva';
    END IF;

    SELECT base_id INTO v_base_id
    FROM tcc_pld.base_sintetica
    WHERE identificador = p_identificador_base;

    v_parametros := jsonb_build_object(
        'quantidade_minima', p_quantidade_minima,
        'janela', p_janela::text,
        'direcao', 'SAIDA',
        'unidade', 'CONTA',
        'limite_inferior', 'ABERTO',
        'limite_superior', 'FECHADO'
    );

    INSERT INTO tcc_pld.regra (codigo, versao, descricao, parametros)
    VALUES (
        'R01',
        p_versao,
        'Frequencia de saidas por conta em janela temporal',
        v_parametros
    )
    ON CONFLICT (codigo, versao) DO NOTHING;

    IF EXISTS (
        SELECT 1
        FROM tcc_pld.regra
        WHERE codigo = 'R01'
          AND versao = p_versao
          AND parametros IS DISTINCT FROM v_parametros
    ) THEN
        RAISE EXCEPTION
            'A versao R01/% ja existe com parametros diferentes',
            p_versao;
    END IF;

    INSERT INTO tcc_pld.execucao_monitoramento
        (identificador_base, estado)
    VALUES
        (p_identificador_base, 'EM_EXECUCAO')
    RETURNING execucao_id INTO v_execucao_id;

    BEGIN
    WITH candidatas AS (
        SELECT
            referencia.transacao_id AS transacao_referencia_id,
            referencia.instante_evento,
            count(evidencia.transacao_id) AS quantidade
        FROM tcc_pld.transacao AS referencia
        JOIN tcc_pld.transacao AS evidencia
          ON evidencia.conta_id = referencia.conta_id
         AND evidencia.base_id IS NOT DISTINCT FROM referencia.base_id
         AND evidencia.direcao = 'SAIDA'
         AND evidencia.instante_evento > referencia.instante_evento - p_janela
         AND evidencia.instante_evento <= referencia.instante_evento
        WHERE referencia.direcao = 'SAIDA'
          AND (
              (v_base_id IS NULL AND referencia.base_id IS NULL)
              OR referencia.base_id = v_base_id
          )
        GROUP BY referencia.transacao_id, referencia.instante_evento
        HAVING count(evidencia.transacao_id) >= p_quantidade_minima
    )
    INSERT INTO tcc_pld.alerta (
        regra_codigo,
        regra_versao,
        execucao_id,
        transacao_referencia_id,
        resultado_observado,
        parametros_utilizados
    )
    SELECT
        'R01',
        p_versao,
        v_execucao_id,
        candidata.transacao_referencia_id,
        jsonb_build_object(
            'quantidade', candidata.quantidade,
            'janela_inicio_exclusiva', candidata.instante_evento - p_janela,
            'janela_fim_inclusiva', candidata.instante_evento
        ),
        v_parametros
    FROM candidatas AS candidata
    ON CONFLICT (regra_codigo, regra_versao, transacao_referencia_id)
        DO NOTHING;

    INSERT INTO tcc_pld.evidencia_alerta
        (alerta_id, transacao_id, registro_observado)
    SELECT
        alerta.alerta_id,
        evidencia.transacao_id,
        to_jsonb(evidencia)
    FROM tcc_pld.alerta AS alerta
    JOIN tcc_pld.transacao AS referencia
      ON referencia.transacao_id = alerta.transacao_referencia_id
    JOIN tcc_pld.transacao AS evidencia
      ON evidencia.conta_id = referencia.conta_id
     AND evidencia.base_id IS NOT DISTINCT FROM referencia.base_id
     AND evidencia.direcao = 'SAIDA'
     AND evidencia.instante_evento > referencia.instante_evento - p_janela
     AND evidencia.instante_evento <= referencia.instante_evento
    WHERE alerta.regra_codigo = 'R01'
      AND alerta.regra_versao = p_versao
      AND alerta.execucao_id = v_execucao_id
      AND alerta.parametros_utilizados = v_parametros
    ON CONFLICT (alerta_id, transacao_id) DO NOTHING;

    UPDATE tcc_pld.execucao_monitoramento
    SET estado = 'CONCLUIDA',
        concluida_em = clock_timestamp()
    WHERE execucao_id = v_execucao_id;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_erro_codigo = RETURNED_SQLSTATE,
            v_erro_mensagem = MESSAGE_TEXT;

        UPDATE tcc_pld.execucao_monitoramento
        SET estado = 'FALHOU',
            concluida_em = clock_timestamp(),
            erro_codigo = v_erro_codigo,
            erro_mensagem = v_erro_mensagem
        WHERE execucao_id = v_execucao_id;

        RAISE WARNING
            'Execucao R01/% falhou [%]: %',
            v_execucao_id, v_erro_codigo, v_erro_mensagem;
    END;
END;
$$;

COMMENT ON PROCEDURE tcc_pld.executar_r01(text, integer, interval, integer) IS
    'Executa R01 em lote sobre base sintetica estavel e registra alertas e evidencias.';

\set ON_ERROR_STOP on
-- Valida a separacao entre base negativa controlada e cenarios positivos.
BEGIN;

CALL tcc_pld.gerar_base_sintetica(
    'TESTE_CONTROLADO',
    100,
    1000,
    20260928
);

CALL tcc_pld.executar_r01('TESTE_CONTROLADO');

DO $$
BEGIN
    IF (SELECT count(*) FROM tcc_pld.alerta) <> 0
       OR NOT EXISTS (
            SELECT 1 FROM tcc_pld.execucao_monitoramento
            WHERE identificador_base = 'TESTE_CONTROLADO'
              AND estado = 'CONCLUIDA'
              AND regra_codigo = 'R01'
              AND regra_versao = 1
       ) THEN
        RAISE EXCEPTION
            'A base de fundo falhou ou gerou alertas antes das injecoes';
    END IF;
    RAISE NOTICE 'BASE NEGATIVA PASSOU: zero alertas';
END;
$$;

CALL tcc_pld.injetar_cenarios_r01(
    'TESTE_CONTROLADO',
    10,
    5
);
CALL tcc_pld.executar_r01('TESTE_CONTROLADO');

DO $$
DECLARE
    v_cenarios integer;
    v_detectados integer;
    v_alertas integer;
    v_evidencias integer;
BEGIN
    SELECT count(*) INTO v_cenarios
    FROM tcc_pld.cenario_r01
    WHERE identificador_base = 'TESTE_CONTROLADO';

    SELECT count(*) INTO v_detectados
    FROM tcc_pld.cenario_r01 AS cenario
    JOIN tcc_pld.alerta AS alerta
      ON alerta.transacao_referencia_id =
         cenario.transacao_referencia_id
    WHERE cenario.identificador_base = 'TESTE_CONTROLADO'
      AND alerta.regra_codigo = 'R01'
      AND alerta.regra_versao = 1;

    SELECT count(*) INTO v_alertas
    FROM tcc_pld.alerta
    WHERE regra_codigo = 'R01' AND regra_versao = 1;

    SELECT count(*) INTO v_evidencias
    FROM tcc_pld.evidencia_alerta AS evidencia
    JOIN tcc_pld.alerta AS alerta USING (alerta_id)
    JOIN tcc_pld.cenario_r01 AS cenario
      ON cenario.conta_id = (
          SELECT transacao.conta_id
          FROM tcc_pld.transacao
          WHERE transacao.transacao_id =
              alerta.transacao_referencia_id
      )
    WHERE cenario.identificador_base = 'TESTE_CONTROLADO';

    IF v_cenarios <> 10 THEN
        RAISE EXCEPTION 'Quantidade de cenarios incorreta: %', v_cenarios;
    END IF;
    IF v_detectados <> 10 THEN
        RAISE EXCEPTION 'Cenarios detectados: 10 esperados, % obtidos', v_detectados;
    END IF;
    IF v_alertas <> 10 THEN
        RAISE EXCEPTION 'Alertas: 10 esperados, % obtidos', v_alertas;
    END IF;
    IF v_evidencias <> 50 THEN
        RAISE EXCEPTION 'Evidencias: 50 esperadas, % obtidas', v_evidencias;
    END IF;
    IF (SELECT count(*) FROM tcc_pld.execucao_monitoramento
        WHERE estado = 'CONCLUIDA') <> 2 THEN
        RAISE EXCEPTION 'Uma das execucoes controladas nao foi concluida';
    END IF;

    RAISE NOTICE
        'PASSOU: 10 cenarios, 10 detectados, 10 alertas e 50 evidencias.';
END;
$$;

ROLLBACK;

\set ON_ERROR_STOP on
BEGIN;

TRUNCATE
    tcc_pld.evidencia_alerta,
    tcc_pld.alerta,
    tcc_pld.execucao_monitoramento,
    tcc_pld.cenario_negativo_r01,
    tcc_pld.cenario_r01,
    tcc_pld.auditoria_transacao,
    tcc_pld.transacao,
    tcc_pld.conta,
    tcc_pld.cliente,
    tcc_pld.regra,
    tcc_pld.base_sintetica
RESTART IDENTITY CASCADE;

CALL tcc_pld.gerar_base_sintetica(
    'TESTE_NEGATIVOS',
    100,
    1000,
    20260928
);

CALL tcc_pld.injetar_cenarios_negativos_r01(
    'TESTE_NEGATIVOS',
    5
);

CALL tcc_pld.executar_r01('TESTE_NEGATIVOS');
DO $$
DECLARE
    v_cenarios bigint;
    v_tipos bigint;
    v_transacoes bigint;
    v_alertas bigint;
BEGIN
    SELECT count(*), count(DISTINCT tipo)
    INTO v_cenarios, v_tipos
    FROM tcc_pld.cenario_negativo_r01;

    SELECT count(*) INTO v_transacoes
    FROM tcc_pld.transacao;

    SELECT count(*) INTO v_alertas
    FROM tcc_pld.alerta;

    IF v_cenarios <> 20 OR v_tipos <> 4 THEN
        RAISE EXCEPTION
            'Esperados 20 cenarios de 4 tipos; obtidos % de % tipos',
            v_cenarios, v_tipos;
    END IF;

    IF v_transacoes <> 1095 THEN
        RAISE EXCEPTION
            'Esperadas 1095 transacoes; obtidas %',
            v_transacoes;
    END IF;

    IF v_alertas <> 0 THEN
        RAISE EXCEPTION
            'Cenarios negativos isolados geraram % alertas',
            v_alertas;
    END IF;

    RAISE NOTICE
        'NEGATIVOS ISOLADOS PASSARAM: 20 cenarios de 4 tipos, zero alertas.';
END;
$$;

TRUNCATE
    tcc_pld.evidencia_alerta,
    tcc_pld.alerta,
    tcc_pld.execucao_monitoramento,
    tcc_pld.regra
RESTART IDENTITY CASCADE;

CALL tcc_pld.injetar_cenarios_r01(
    'TESTE_NEGATIVOS',
    10,
    5
);

CALL tcc_pld.executar_r01('TESTE_NEGATIVOS');

DO $$
DECLARE
    v_alertas bigint;
    v_evidencias bigint;
    v_alertas_fora_positivos bigint;
BEGIN
    SELECT count(*) INTO v_alertas
    FROM tcc_pld.alerta;

    SELECT count(*) INTO v_evidencias
    FROM tcc_pld.evidencia_alerta;
    SELECT count(*)
    INTO v_alertas_fora_positivos
    FROM tcc_pld.alerta AS alerta
    LEFT JOIN tcc_pld.cenario_r01 AS positivo
      ON positivo.transacao_referencia_id =
         alerta.transacao_referencia_id
    WHERE positivo.cenario_id IS NULL;

    IF v_alertas <> 10 THEN
        RAISE EXCEPTION
            'Esperados 10 alertas positivos; obtidos %',
            v_alertas;
    END IF;

    IF v_evidencias <> 50 THEN
        RAISE EXCEPTION
            'Esperadas 50 evidencias; obtidas %',
            v_evidencias;
    END IF;

    IF v_alertas_fora_positivos <> 0 THEN
        RAISE EXCEPTION
            'Foram gerados % alertas fora dos positivos construidos',
            v_alertas_fora_positivos;
    END IF;

    RAISE NOTICE
        'MISTURA PASSOU: 20 negativos, 10 positivos, 10 alertas e 50 evidencias.';
END;
$$;

ROLLBACK;

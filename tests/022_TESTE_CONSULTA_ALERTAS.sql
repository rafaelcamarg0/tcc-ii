\set ON_ERROR_STOP on
-- Valida a consulta legivel para revisao humana.
BEGIN;

TRUNCATE
    tcc_pld.evidencia_alerta,
    tcc_pld.alerta,
    tcc_pld.execucao_monitoramento,
    tcc_pld.regra,
    tcc_pld.cenario_r01,
    tcc_pld.transacao,
    tcc_pld.conta,
    tcc_pld.cliente,
    tcc_pld.base_sintetica
RESTART IDENTITY CASCADE;

CALL tcc_pld.gerar_base_sintetica(
    'TESTE_CONSULTA', 10, 100, 20260929
);
CALL tcc_pld.injetar_cenarios_r01(
    'TESTE_CONSULTA', 1, 5
);
CALL tcc_pld.executar_r01('TESTE_CONSULTA');

DO $$
BEGIN
    IF (SELECT count(*) FROM tcc_pld.vw_alerta_explicado) <> 1 THEN
        RAISE EXCEPTION 'A consulta nao retornou um alerta';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tcc_pld.vw_alerta_explicado
        WHERE identificador_base = 'TESTE_CONSULTA'
          AND regra_codigo = 'R01'
          AND regra_versao = 1
          AND estado_execucao = 'CONCLUIDA'
          AND cliente LIKE 'TESTE_CONSULTA_R01_POS_%_CLI'
          AND conta LIKE 'TESTE_CONSULTA_R01_POS_%_CONTA'
          AND transacao_referencia LIKE 'TESTE_CONSULTA_R01_POS_%_TX_5'
          AND quantidade_observada = 5
          AND quantidade_evidencias = 5
          AND jsonb_array_length(evidencias) = 5
    ) THEN
        RAISE EXCEPTION
            'A consulta nao reconstruiu regra, base, referencia e evidencias';
    END IF;

    RAISE NOTICE
        'CONSULTA DE ALERTAS PASSOU: alerta explicavel com 5 evidencias';
END;
$$;

SELECT alerta_id, regra_codigo, regra_versao, identificador_base,
       cliente, conta, transacao_referencia, quantidade_observada,
       quantidade_evidencias
FROM tcc_pld.vw_alerta_explicado;

ROLLBACK;

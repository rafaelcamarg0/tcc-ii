\set ON_ERROR_STOP on
-- Verifica que a R01 processa somente a base sintetica identificada.
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

CALL tcc_pld.gerar_base_sintetica('ISOLADA_A', 1, 0, 101);
CALL tcc_pld.gerar_base_sintetica('ISOLADA_B', 1, 0, 202);
CALL tcc_pld.injetar_cenarios_r01('ISOLADA_A', 1, 5);
CALL tcc_pld.injetar_cenarios_r01('ISOLADA_B', 1, 5);

CALL tcc_pld.executar_r01('ISOLADA_A');

DO $$
BEGIN
    IF (SELECT count(*) FROM tcc_pld.alerta) <> 1
       OR (SELECT count(*) FROM tcc_pld.execucao_monitoramento
           WHERE estado = 'CONCLUIDA') <> 1
       OR NOT EXISTS (
            SELECT 1
            FROM tcc_pld.alerta AS a
            JOIN tcc_pld.transacao AS t
              ON t.transacao_id = a.transacao_referencia_id
            JOIN tcc_pld.base_sintetica AS b USING (base_id)
            WHERE b.identificador = 'ISOLADA_A'
       ) THEN
        RAISE EXCEPTION 'R01 nao isolou a base A';
    END IF;
END;
$$;

CALL tcc_pld.executar_r01('ISOLADA_B');

DO $$
BEGIN
    IF (SELECT count(*) FROM tcc_pld.alerta) <> 2
       OR (SELECT count(*) FROM tcc_pld.execucao_monitoramento
           WHERE estado = 'CONCLUIDA') <> 2
       OR (SELECT count(DISTINCT b.identificador)
           FROM tcc_pld.alerta AS a
           JOIN tcc_pld.transacao AS t
             ON t.transacao_id = a.transacao_referencia_id
           JOIN tcc_pld.base_sintetica AS b USING (base_id)) <> 2
       OR EXISTS (
           SELECT 1 FROM tcc_pld.transacao
           WHERE codigo_sintetico LIKE 'ISOLADA_%'
             AND base_id IS NULL
       ) THEN
        RAISE EXCEPTION 'Isolamento entre bases falhou';
    END IF;
    RAISE NOTICE 'ISOLAMENTO DE BASES PASSOU';
END;
$$;

ROLLBACK;

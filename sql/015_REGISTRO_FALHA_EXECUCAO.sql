-- Migra bases existentes para registrar falhas de monitoramento.
BEGIN;

ALTER TABLE tcc_pld.execucao_monitoramento
    ADD COLUMN IF NOT EXISTS erro_codigo text,
    ADD COLUMN IF NOT EXISTS erro_mensagem text;

ALTER TABLE tcc_pld.execucao_monitoramento
    DROP CONSTRAINT IF EXISTS execucao_estado_detalhes_check;

ALTER TABLE tcc_pld.execucao_monitoramento
    ADD CONSTRAINT execucao_estado_detalhes_check CHECK (
        (estado = 'EM_EXECUCAO' AND concluida_em IS NULL
            AND erro_codigo IS NULL AND erro_mensagem IS NULL)
        OR (estado = 'CONCLUIDA' AND concluida_em IS NOT NULL
            AND erro_codigo IS NULL AND erro_mensagem IS NULL)
        OR (estado = 'FALHOU' AND concluida_em IS NOT NULL
            AND erro_codigo IS NOT NULL AND erro_mensagem IS NOT NULL)
    );

COMMIT;
-- Associa transacoes a uma base sintetica sem alterar registros legados.
BEGIN;

ALTER TABLE tcc_pld.transacao
    ADD COLUMN IF NOT EXISTS base_id bigint;

ALTER TABLE tcc_pld.transacao
    DROP CONSTRAINT IF EXISTS transacao_base_sintetica_fk;

ALTER TABLE tcc_pld.transacao
    ADD CONSTRAINT transacao_base_sintetica_fk
        FOREIGN KEY (base_id)
        REFERENCES tcc_pld.base_sintetica (base_id);

COMMIT;
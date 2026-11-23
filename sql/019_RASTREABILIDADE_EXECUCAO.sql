-- Acrescenta rastreabilidade diretamente ao registro de execucao.
BEGIN;

ALTER TABLE tcc_pld.execucao_monitoramento
    ADD COLUMN IF NOT EXISTS regra_codigo text,
    ADD COLUMN IF NOT EXISTS regra_versao integer,
    ADD COLUMN IF NOT EXISTS parametros_utilizados jsonb;

ALTER TABLE tcc_pld.execucao_monitoramento
    DROP CONSTRAINT IF EXISTS execucao_regra_parametros_check;

ALTER TABLE tcc_pld.execucao_monitoramento
    ADD CONSTRAINT execucao_regra_parametros_check CHECK (
        (regra_codigo IS NULL AND regra_versao IS NULL
            AND parametros_utilizados IS NULL)
        OR (regra_codigo IS NOT NULL
            AND regra_versao IS NOT NULL AND regra_versao > 0
            AND parametros_utilizados IS NOT NULL
            AND jsonb_typeof(parametros_utilizados) = 'object')
    );

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'execucao_regra_fk'
          AND conrelid = 'tcc_pld.execucao_monitoramento'::regclass
    ) THEN
        ALTER TABLE tcc_pld.execucao_monitoramento
            ADD CONSTRAINT execucao_regra_fk
            FOREIGN KEY (regra_codigo, regra_versao)
            REFERENCES tcc_pld.regra (codigo, versao)
            NOT VALID;
    END IF;
END;
$$;

ALTER TABLE tcc_pld.execucao_monitoramento
    VALIDATE CONSTRAINT execucao_regra_fk;

COMMENT ON COLUMN tcc_pld.execucao_monitoramento.parametros_utilizados IS
    'Parametros preservados mesmo quando a execucao nao produz alertas.';

COMMIT;

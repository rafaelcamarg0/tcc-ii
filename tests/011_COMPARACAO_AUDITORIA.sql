\set ON_ERROR_STOP on
BEGIN;

CREATE TEMP TABLE comparacao_auditoria (
    condicao text NOT NULL,
    repeticao integer NOT NULL,
    duracao_ms numeric NOT NULL,
    transacoes bigint NOT NULL,
    registros_auditoria bigint NOT NULL,
    PRIMARY KEY (condicao, repeticao)
) ON COMMIT DROP;

DO $$
DECLARE
    v_repeticao integer;
    v_condicao text;
    v_condicoes text[];
    v_inicio timestamptz;
    v_duracao_ms numeric;
    v_transacoes bigint;
    v_auditorias bigint;
BEGIN
    FOR v_repeticao IN 0..5 LOOP
        IF v_repeticao % 2 = 0 THEN
            v_condicoes := ARRAY['COM_AUDITORIA', 'SEM_AUDITORIA'];
        ELSE
            v_condicoes := ARRAY['SEM_AUDITORIA', 'COM_AUDITORIA'];
        END IF;

        FOREACH v_condicao IN ARRAY v_condicoes LOOP
            TRUNCATE
                tcc_pld.evidencia_alerta,
                tcc_pld.alerta,
                tcc_pld.execucao_monitoramento,
                tcc_pld.cenario_r01,
                tcc_pld.auditoria_transacao,
                tcc_pld.transacao,
                tcc_pld.conta,
                tcc_pld.cliente,
                tcc_pld.regra,
                tcc_pld.base_sintetica
            RESTART IDENTITY CASCADE;

            IF v_condicao = 'COM_AUDITORIA' THEN
                ALTER TABLE tcc_pld.transacao
                    ENABLE TRIGGER auditar_transacao;
            ELSE
                ALTER TABLE tcc_pld.transacao
                    DISABLE TRIGGER auditar_transacao;
            END IF;

            v_inicio := clock_timestamp();
            CALL tcc_pld.gerar_base_sintetica(
                'BENCH_AUDITORIA',
                10000,
                100000,
                20260928
            );
            v_duracao_ms :=
                extract(epoch FROM clock_timestamp() - v_inicio) * 1000;

            SELECT count(*) INTO v_transacoes
            FROM tcc_pld.transacao;
            SELECT count(*) INTO v_auditorias
            FROM tcc_pld.auditoria_transacao;

            IF v_transacoes <> 100000 THEN
                RAISE EXCEPTION 'Quantidade de transacoes incorreta';
            END IF;
            IF v_condicao = 'COM_AUDITORIA' AND v_auditorias <> 100000 THEN
                RAISE EXCEPTION 'Auditoria habilitada nao registrou todas as transacoes';
            END IF;
            IF v_condicao = 'SEM_AUDITORIA' AND v_auditorias <> 0 THEN
                RAISE EXCEPTION 'Auditoria desabilitada gerou registros';
            END IF;

            IF v_repeticao > 0 THEN
                INSERT INTO comparacao_auditoria VALUES (
                    v_condicao,
                    v_repeticao,
                    v_duracao_ms,
                    v_transacoes,
                    v_auditorias
                );
            END IF;
        END LOOP;
    END LOOP;

    ALTER TABLE tcc_pld.transacao
        ENABLE TRIGGER auditar_transacao;
END;
$$;

SELECT
    condicao,
    repeticao,
    round(duracao_ms, 3) AS duracao_ms,
    transacoes,
    registros_auditoria
FROM comparacao_auditoria
ORDER BY repeticao, condicao;

WITH resumo AS (
    SELECT
        condicao,
        percentile_cont(0.5) WITHIN GROUP
            (ORDER BY duracao_ms) AS mediana_ms,
        stddev_samp(duracao_ms) AS desvio_ms
    FROM comparacao_auditoria
    GROUP BY condicao
)
SELECT
    condicao,
    round(mediana_ms::numeric, 3) AS mediana_ms,
    round(desvio_ms, 3) AS desvio_ms
FROM resumo
ORDER BY condicao;

WITH medianas AS (
    SELECT
        percentile_cont(0.5) WITHIN GROUP (ORDER BY duracao_ms)
            FILTER (WHERE condicao = 'COM_AUDITORIA') AS com_auditoria,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY duracao_ms)
            FILTER (WHERE condicao = 'SEM_AUDITORIA') AS sem_auditoria
    FROM comparacao_auditoria
)
SELECT round(
    ((com_auditoria - sem_auditoria) / sem_auditoria * 100)::numeric,
    2
) AS sobrecarga_percentual_mediana
FROM medianas;

ROLLBACK;

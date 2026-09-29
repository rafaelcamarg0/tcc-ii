\set ON_ERROR_STOP on
BEGIN;

CREATE TEMP TABLE comparacao_indice (
    condicao text NOT NULL,
    repeticao integer NOT NULL,
    duracao_ms numeric NOT NULL,
    alertas bigint NOT NULL,
    evidencias bigint NOT NULL,
    PRIMARY KEY (condicao, repeticao)
) ON COMMIT DROP;

CALL tcc_pld.gerar_base_sintetica(
    'BENCH_INDICE',
    1000,
    10000,
    20260928
);
CALL tcc_pld.injetar_cenarios_r01(
    'BENCH_INDICE',
    100,
    5
);

DO $$
DECLARE
    v_repeticao integer;
    v_condicao text;
    v_condicoes text[];
    v_inicio timestamptz;
    v_duracao_ms numeric;
    v_alertas bigint;
    v_evidencias bigint;
BEGIN
    FOR v_repeticao IN 0..5 LOOP
        IF v_repeticao % 2 = 0 THEN
            v_condicoes := ARRAY['COM_INDICE', 'SEM_INDICE'];
        ELSE
            v_condicoes := ARRAY['SEM_INDICE', 'COM_INDICE'];
        END IF;

        FOREACH v_condicao IN ARRAY v_condicoes LOOP
            TRUNCATE
                tcc_pld.evidencia_alerta,
                tcc_pld.alerta,
                tcc_pld.execucao_monitoramento,
                tcc_pld.regra
            RESTART IDENTITY CASCADE;

            IF v_condicao = 'COM_INDICE' THEN
                CREATE INDEX IF NOT EXISTS transacao_conta_instante_idx
                    ON tcc_pld.transacao (conta_id, instante_evento);
            ELSE
                DROP INDEX IF EXISTS tcc_pld.transacao_conta_instante_idx;
            END IF;

            v_inicio := clock_timestamp();
            CALL tcc_pld.executar_r01('BENCH_INDICE');
            v_duracao_ms :=
                extract(epoch FROM clock_timestamp() - v_inicio) * 1000;

            SELECT count(*) INTO v_alertas
            FROM tcc_pld.alerta;
            SELECT count(*) INTO v_evidencias
            FROM tcc_pld.evidencia_alerta;

            IF v_alertas <> 100 THEN
                RAISE EXCEPTION
                    'Condicao %, repeticao %: alertas esperados 100, obtidos %',
                    v_condicao, v_repeticao, v_alertas;
            END IF;
            IF v_evidencias <> 500 THEN
                RAISE EXCEPTION
                    'Condicao %, repeticao %: evidencias esperadas 500, obtidas %',
                    v_condicao, v_repeticao, v_evidencias;
            END IF;

            IF v_repeticao > 0 THEN
                INSERT INTO comparacao_indice VALUES (
                    v_condicao,
                    v_repeticao,
                    v_duracao_ms,
                    v_alertas,
                    v_evidencias
                );
            END IF;
        END LOOP;
    END LOOP;

    CREATE INDEX IF NOT EXISTS transacao_conta_instante_idx
        ON tcc_pld.transacao (conta_id, instante_evento);
END;
$$;

SELECT
    condicao,
    repeticao,
    round(duracao_ms, 3) AS duracao_ms,
    alertas,
    evidencias
FROM comparacao_indice
ORDER BY repeticao, condicao;

WITH resumo AS (
    SELECT
        condicao,
        percentile_cont(0.5) WITHIN GROUP
            (ORDER BY duracao_ms) AS mediana_ms,
        stddev_samp(duracao_ms) AS desvio_ms
    FROM comparacao_indice
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
            FILTER (WHERE condicao = 'COM_INDICE') AS com_indice,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY duracao_ms)
            FILTER (WHERE condicao = 'SEM_INDICE') AS sem_indice
    FROM comparacao_indice
)
SELECT round(
    ((sem_indice - com_indice) / sem_indice * 100)::numeric,
    2
) AS ganho_percentual_mediano
FROM medianas;

ROLLBACK;

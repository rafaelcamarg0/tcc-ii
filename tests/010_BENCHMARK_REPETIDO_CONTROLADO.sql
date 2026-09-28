\set ON_ERROR_STOP on
BEGIN;

CREATE TEMP TABLE benchmark_resultado (
    volume_base integer NOT NULL,
    repeticao integer NOT NULL,
    clientes integer NOT NULL,
    cenarios_positivos integer NOT NULL,
    transacoes_totais bigint NOT NULL,
    alertas bigint NOT NULL,
    evidencias bigint NOT NULL,
    geracao_ms numeric NOT NULL,
    injecao_ms numeric NOT NULL,
    r01_ms numeric NOT NULL,
    PRIMARY KEY (volume_base, repeticao)
) ON COMMIT DROP;

DO $$
DECLARE
    v_volume integer;
    v_repeticao integer;
    v_clientes integer;
    v_cenarios integer;
    v_identificador text;
    v_inicio timestamptz;
    v_geracao_ms numeric;
    v_injecao_ms numeric;
    v_r01_ms numeric;
    v_transacoes bigint;
    v_alertas bigint;
    v_evidencias bigint;
BEGIN
    FOREACH v_volume IN ARRAY ARRAY[1000, 10000, 100000] LOOP
        v_clientes := v_volume / 10;
        v_cenarios := v_volume / 100;
        v_identificador := 'BENCH_CTRL_' || v_volume;

        FOR v_repeticao IN 0..5 LOOP
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

            v_inicio := clock_timestamp();
            CALL tcc_pld.gerar_base_sintetica(
                v_identificador,
                v_clientes,
                v_volume,
                20260928
            );
            v_geracao_ms :=
                extract(epoch FROM clock_timestamp() - v_inicio) * 1000;

            v_inicio := clock_timestamp();
            CALL tcc_pld.injetar_cenarios_r01(
                v_identificador,
                v_cenarios,
                5
            );
            v_injecao_ms :=
                extract(epoch FROM clock_timestamp() - v_inicio) * 1000;

            v_inicio := clock_timestamp();
            CALL tcc_pld.executar_r01(
                v_identificador || '_REP_' || v_repeticao
            );
            v_r01_ms :=
                extract(epoch FROM clock_timestamp() - v_inicio) * 1000;

            SELECT count(*) INTO v_transacoes
            FROM tcc_pld.transacao;
            SELECT count(*) INTO v_alertas
            FROM tcc_pld.alerta;
            SELECT count(*) INTO v_evidencias
            FROM tcc_pld.evidencia_alerta;

            IF v_alertas <> v_cenarios THEN
                RAISE EXCEPTION
                    'Volume %, repeticao %: % alertas esperados, % obtidos',
                    v_volume, v_repeticao, v_cenarios, v_alertas;
            END IF;
            IF v_evidencias <> v_cenarios * 5 THEN
                RAISE EXCEPTION
                    'Volume %, repeticao %: % evidencias esperadas, % obtidas',
                    v_volume, v_repeticao, v_cenarios * 5, v_evidencias;
            END IF;

            IF v_repeticao > 0 THEN
                INSERT INTO benchmark_resultado VALUES (
                    v_volume,
                    v_repeticao,
                    v_clientes,
                    v_cenarios,
                    v_transacoes,
                    v_alertas,
                    v_evidencias,
                    v_geracao_ms,
                    v_injecao_ms,
                    v_r01_ms
                );
            END IF;
        END LOOP;
    END LOOP;
END;
$$;

SELECT
    volume_base,
    repeticao,
    clientes,
    cenarios_positivos,
    transacoes_totais,
    alertas,
    evidencias,
    round(geracao_ms, 3) AS geracao_ms,
    round(injecao_ms, 3) AS injecao_ms,
    round(r01_ms, 3) AS r01_ms
FROM benchmark_resultado
ORDER BY volume_base, repeticao;

SELECT
    volume_base,
    round(percentile_cont(0.5) WITHIN GROUP
        (ORDER BY geracao_ms)::numeric, 3) AS mediana_geracao_ms,
    round(stddev_samp(geracao_ms), 3) AS desvio_geracao_ms,
    round(percentile_cont(0.5) WITHIN GROUP
        (ORDER BY injecao_ms)::numeric, 3) AS mediana_injecao_ms,
    round(stddev_samp(injecao_ms), 3) AS desvio_injecao_ms,
    round(percentile_cont(0.5) WITHIN GROUP
        (ORDER BY r01_ms)::numeric, 3) AS mediana_r01_ms,
    round(stddev_samp(r01_ms), 3) AS desvio_r01_ms
FROM benchmark_resultado
GROUP BY volume_base
ORDER BY volume_base;

ROLLBACK;

\set ON_ERROR_STOP on
-- Valida entradas obrigatorias, base explicita e rastreabilidade sem alertas.
BEGIN;

TRUNCATE
    tcc_pld.evidencia_alerta,
    tcc_pld.alerta,
    tcc_pld.execucao_monitoramento,
    tcc_pld.regra
RESTART IDENTITY CASCADE;

DO $$
DECLARE
    v_quantidade_null boolean := false;
    v_janela_null boolean := false;
    v_versao_null boolean := false;
    v_base_inexistente boolean := false;
BEGIN
    BEGIN
        CALL tcc_pld.executar_r01(
            'LEGADO_SEM_BASE', NULL, interval '10 minutes', 1
        );
    EXCEPTION WHEN OTHERS THEN
        v_quantidade_null := SQLERRM =
            'A quantidade minima deve ser maior ou igual a 2';
    END;
    BEGIN
        CALL tcc_pld.executar_r01(
            'LEGADO_SEM_BASE', 5, NULL, 1
        );
    EXCEPTION WHEN OTHERS THEN
        v_janela_null := SQLERRM = 'A janela deve ser positiva';
    END;

    BEGIN
        CALL tcc_pld.executar_r01(
            'LEGADO_SEM_BASE', 5, interval '10 minutes', NULL
        );
    EXCEPTION WHEN OTHERS THEN
        v_versao_null := SQLERRM = 'A versao deve ser positiva';
    END;

    BEGIN
        CALL tcc_pld.executar_r01(
            'BASE_DIGITADA_INCORRETAMENTE', 5, interval '10 minutes', 1
        );
    EXCEPTION WHEN OTHERS THEN
        v_base_inexistente := SQLERRM =
            'Base sintetica BASE_DIGITADA_INCORRETAMENTE nao encontrada';
    END;

    IF NOT (
        v_quantidade_null
        AND v_janela_null
        AND v_versao_null
        AND v_base_inexistente
    ) THEN
        RAISE EXCEPTION
            'Validacoes obrigatorias da R01 nao rejeitaram todas as entradas';
    END IF;

    IF EXISTS (SELECT 1 FROM tcc_pld.execucao_monitoramento) THEN
        RAISE EXCEPTION
            'Entrada invalida abriu registro de execucao';
    END IF;
END;
$$;

CALL tcc_pld.executar_r01('LEGADO_SEM_BASE');

DO $$
DECLARE
    v_metadados_parciais_rejeitados boolean := false;
BEGIN
    BEGIN
        INSERT INTO tcc_pld.execucao_monitoramento (
            identificador_base, regra_codigo, regra_versao, estado
        ) VALUES ('PARCIAL_INVALIDA', 'R01', 1, 'EM_EXECUCAO');
    EXCEPTION WHEN not_null_violation OR check_violation THEN
        v_metadados_parciais_rejeitados := true;
    END;

    IF NOT v_metadados_parciais_rejeitados THEN
        RAISE EXCEPTION 'Execucao aceitou metadados parciais';
    END IF;

    IF (SELECT count(*) FROM tcc_pld.alerta) <> 0
       OR NOT EXISTS (
            SELECT 1
            FROM tcc_pld.execucao_monitoramento
            WHERE identificador_base = 'LEGADO_SEM_BASE'
              AND regra_codigo = 'R01'
              AND regra_versao = 1
              AND estado = 'CONCLUIDA'
              AND parametros_utilizados @>
                  '{"quantidade_minima": 5, "janela": "00:10:00"}'::jsonb
       ) THEN
        RAISE EXCEPTION
            'Execucao sem alertas nao preservou regra, parametros e estado';
    END IF;

    RAISE NOTICE
        'VALIDACOES E RASTREABILIDADE DA EXECUCAO PASSARAM';
END;
$$;

ROLLBACK;

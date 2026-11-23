\set ON_ERROR_STOP on
\pset pager off

\echo ============================================================
\echo DEMONSTRACAO DO PROTOTIPO DE AUDITORIA E MONITORAMENTO PLD/FT
\echo ============================================================
BEGIN;

TRUNCATE
    tcc_pld.evidencia_alerta,
    tcc_pld.alerta,
    tcc_pld.execucao_monitoramento,
    tcc_pld.regra,
    tcc_pld.cenario_negativo_r01,
    tcc_pld.cenario_r01,
    tcc_pld.auditoria_transacao,
    tcc_pld.transacao,
    tcc_pld.conta,
    tcc_pld.cliente,
    tcc_pld.base_sintetica
RESTART IDENTITY CASCADE;

\echo
\echo ETAPA 1 - Gerar 100 transacoes sinteticas reproduziveis
CALL tcc_pld.gerar_base_sintetica(
    'DEMO_ORIENTACAO', 10, 100, 20260929
);

\echo ETAPA 2 - Executar a R01 sobre a base de fundo
CALL tcc_pld.executar_r01('DEMO_ORIENTACAO');
SELECT execucao_id AS execucao, identificador_base AS base, estado,
       (SELECT count(*) FROM tcc_pld.transacao) AS movimentos,
       (SELECT count(*) FROM tcc_pld.alerta) AS alertas
FROM tcc_pld.execucao_monitoramento ORDER BY execucao_id;
DO $$
BEGIN
    IF (SELECT count(*) FROM tcc_pld.transacao) <> 100
       OR EXISTS (SELECT 1 FROM tcc_pld.alerta)
       OR (SELECT count(*) FROM tcc_pld.execucao_monitoramento
           WHERE estado = 'CONCLUIDA') <> 1 THEN
        RAISE EXCEPTION 'A etapa de fundo divergiu do esperado';
    END IF;
END;
$$;

\echo
\echo ETAPA 3 - Injetar um cenario positivo conhecido e reexecutar
CALL tcc_pld.injetar_cenarios_r01(
    'DEMO_ORIENTACAO', 1, 5
);
CALL tcc_pld.executar_r01('DEMO_ORIENTACAO');

\echo
\echo ETAPA 4 - Reconstruir o alerta para revisao humana
SELECT execucao_id AS execucao, regra_codigo AS regra, regra_versao AS versao,
       identificador_base AS base, estado_execucao AS estado,
       parametros_utilizados->>'quantidade_minima' AS n,
       parametros_utilizados->>'janela' AS w
FROM tcc_pld.vw_alerta_explicado ORDER BY alerta_id;

SELECT alerta_id AS alerta, conta, transacao_referencia AS referencia,
       quantidade_observada AS saidas, quantidade_evidencias AS evidencias
FROM tcc_pld.vw_alerta_explicado ORDER BY alerta_id;

\echo ETAPA 4b - Movimentos preservados na contagem (hora de Brasilia)
SELECT v.alerta_id AS alerta, e->>'codigo_sintetico' AS codigo,
       to_char((e->>'instante_evento')::timestamptz AT TIME ZONE 'America/Sao_Paulo',
               'YYYY-MM-DD HH24:MI:SS') AS horario_brasilia,
       e->>'direcao' AS direcao, (e->>'valor')::numeric AS valor
FROM tcc_pld.vw_alerta_explicado AS v
CROSS JOIN LATERAL jsonb_array_elements(v.evidencias) AS dados(e)
ORDER BY v.alerta_id, (e->>'instante_evento')::timestamptz, e->>'codigo_sintetico';

\echo
\echo ETAPA 5 - Conferir a trilha automatica de auditoria
SELECT operacao, count(*) AS registros_auditoria
FROM tcc_pld.auditoria_transacao
GROUP BY operacao
ORDER BY operacao;

DO $$
BEGIN
    IF (SELECT count(*) FROM tcc_pld.alerta) <> 1
       OR (SELECT count(*) FROM tcc_pld.evidencia_alerta) <> 5
       OR (SELECT count(*) FROM tcc_pld.auditoria_transacao
           WHERE operacao = 'INSERT') <> 105
       OR (SELECT count(*) FROM tcc_pld.execucao_monitoramento
           WHERE estado = 'CONCLUIDA') <> 2
       OR NOT EXISTS (
           SELECT 1 FROM tcc_pld.vw_alerta_explicado
           WHERE regra_codigo = 'R01' AND regra_versao = 1
             AND quantidade_observada = 5 AND quantidade_evidencias = 5
             AND transacao_referencia = 'DEMO_ORIENTACAO_R01_POS_1_TX_5'
       ) THEN
        RAISE EXCEPTION 'O resultado final da demonstracao divergiu do esperado';
    END IF;
END;
$$;
ROLLBACK;
\echo
\echo DEMONSTRACAO CONCLUIDA. Os dados temporarios foram revertidos.

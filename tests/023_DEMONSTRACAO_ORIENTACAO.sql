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
SELECT execucao_id, identificador_base, regra_codigo, regra_versao,
       estado, parametros_utilizados,
       (SELECT count(*) FROM tcc_pld.alerta) AS alertas_gerados
FROM tcc_pld.execucao_monitoramento
ORDER BY execucao_id;

\echo
\echo ETAPA 3 - Injetar um cenario positivo conhecido e reexecutar
CALL tcc_pld.injetar_cenarios_r01(
    'DEMO_ORIENTACAO', 1, 5
);
CALL tcc_pld.executar_r01('DEMO_ORIENTACAO');

\echo
\echo ETAPA 4 - Reconstruir o alerta para revisao humana
SELECT alerta_id, regra_codigo, regra_versao, identificador_base,
       cliente, conta, transacao_referencia, quantidade_observada,
       quantidade_evidencias
FROM tcc_pld.vw_alerta_explicado
ORDER BY alerta_id;

\echo
\echo ETAPA 5 - Conferir a trilha automatica de auditoria
SELECT operacao, count(*) AS registros_auditoria
FROM tcc_pld.auditoria_transacao
GROUP BY operacao
ORDER BY operacao;

ROLLBACK;
\echo
\echo DEMONSTRACAO CONCLUIDA. Os dados temporarios foram revertidos.

\set ON_ERROR_STOP on
\timing on

\echo VOLUME_1K
BEGIN;
CALL tcc_pld.gerar_base_sintetica('BENCH_1K', 100, 1000, 20260928);
SELECT count(*) AS transacoes FROM tcc_pld.transacao;
SELECT count(*) AS auditorias FROM tcc_pld.auditoria_transacao;
CALL tcc_pld.executar_r01('BENCH_1K');
SELECT count(*) AS alertas FROM tcc_pld.alerta;
ROLLBACK;

\echo VOLUME_10K
BEGIN;
CALL tcc_pld.gerar_base_sintetica('BENCH_10K', 1000, 10000, 20260928);
SELECT count(*) AS transacoes FROM tcc_pld.transacao;
SELECT count(*) AS auditorias FROM tcc_pld.auditoria_transacao;
CALL tcc_pld.executar_r01('BENCH_10K');
SELECT count(*) AS alertas FROM tcc_pld.alerta;
ROLLBACK;

\echo VOLUME_100K
BEGIN;
CALL tcc_pld.gerar_base_sintetica('BENCH_100K', 10000, 100000, 20260928);
SELECT count(*) AS transacoes FROM tcc_pld.transacao;
SELECT count(*) AS auditorias FROM tcc_pld.auditoria_transacao;
CALL tcc_pld.executar_r01('BENCH_100K');
SELECT count(*) AS alertas FROM tcc_pld.alerta;
ROLLBACK;

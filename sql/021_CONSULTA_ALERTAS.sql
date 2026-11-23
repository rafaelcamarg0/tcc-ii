-- Camada de consulta para reconstruir alertas de forma legivel.
-- Usa os snapshots das evidencias preservados no momento do disparo.
CREATE OR REPLACE VIEW tcc_pld.vw_alerta_explicado AS
SELECT
    alerta.alerta_id,
    alerta.regra_codigo,
    alerta.regra_versao,
    execucao.execucao_id,
    execucao.identificador_base,
    execucao.estado AS estado_execucao,
    execucao.iniciada_em,
    execucao.concluida_em,
    cliente.codigo_sintetico AS cliente,
    conta.codigo_sintetico AS conta,
    referencia.codigo_sintetico AS transacao_referencia,
    referencia.instante_evento AS instante_referencia,
    referencia.valor AS valor_referencia,
    (alerta.resultado_observado->>'quantidade')::integer
        AS quantidade_observada,
    alerta.resultado_observado,
    alerta.parametros_utilizados,
    count(evidencia.transacao_id)::integer AS quantidade_evidencias,
    jsonb_agg(
        evidencia.registro_observado
        ORDER BY evidencia.transacao_id
    ) AS evidencias
FROM tcc_pld.alerta AS alerta
JOIN tcc_pld.execucao_monitoramento AS execucao
  ON execucao.execucao_id = alerta.execucao_id
JOIN tcc_pld.transacao AS referencia
  ON referencia.transacao_id = alerta.transacao_referencia_id
JOIN tcc_pld.conta AS conta
  ON conta.conta_id = referencia.conta_id
JOIN tcc_pld.cliente AS cliente
  ON cliente.cliente_id = conta.cliente_id
JOIN tcc_pld.evidencia_alerta AS evidencia
  ON evidencia.alerta_id = alerta.alerta_id
GROUP BY
    alerta.alerta_id,
    execucao.execucao_id,
    cliente.codigo_sintetico,
    conta.codigo_sintetico,
    referencia.codigo_sintetico,
    referencia.instante_evento,
    referencia.valor;

COMMENT ON VIEW tcc_pld.vw_alerta_explicado IS
    'Reconstrucao legivel do alerta, execucao, referencia e evidencias para revisao humana.';

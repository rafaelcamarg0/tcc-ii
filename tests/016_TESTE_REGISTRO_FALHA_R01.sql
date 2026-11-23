\set ON_ERROR_STOP on
-- Verifica persistencia do estado FALHOU em erro interno controlado.
BEGIN;

TRUNCATE
    tcc_pld.evidencia_alerta,
    tcc_pld.alerta,
    tcc_pld.execucao_monitoramento,
    tcc_pld.auditoria_transacao,
    tcc_pld.transacao,
    tcc_pld.conta,
    tcc_pld.cliente,
    tcc_pld.regra
RESTART IDENTITY CASCADE;

INSERT INTO tcc_pld.cliente (codigo_sintetico, tipo)
VALUES ('FALHA_CLI', 'PF');

INSERT INTO tcc_pld.conta (codigo_sintetico, cliente_id, data_abertura)
SELECT 'FALHA_CTA', cliente_id, DATE '2026-01-01'
FROM tcc_pld.cliente
WHERE codigo_sintetico = 'FALHA_CLI';

INSERT INTO tcc_pld.transacao
    (codigo_sintetico, conta_id, instante_evento, direcao, valor)
SELECT 'FALHA_' || i, conta_id,
       TIMESTAMPTZ '2026-09-01 12:00:00-03' + i * interval '1 minute',
       'SAIDA', 100
FROM tcc_pld.conta
CROSS JOIN generate_series(0, 4) AS g(i)
WHERE codigo_sintetico = 'FALHA_CTA';
CREATE FUNCTION pg_temp.impedir_alerta()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'falha controlada ao persistir alerta';
END;
$$;

CREATE TRIGGER teste_impedir_alerta
BEFORE INSERT ON tcc_pld.alerta
FOR EACH ROW EXECUTE FUNCTION pg_temp.impedir_alerta();

CALL tcc_pld.executar_r01('LEGADO_SEM_BASE');

DROP TRIGGER teste_impedir_alerta ON tcc_pld.alerta;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM tcc_pld.execucao_monitoramento
        WHERE identificador_base = 'LEGADO_SEM_BASE'
          AND regra_codigo = 'R01'
          AND regra_versao = 1
          AND parametros_utilizados @> '{"quantidade_minima": 5}'::jsonb
          AND estado = 'FALHOU'
          AND concluida_em IS NOT NULL
          AND erro_codigo = 'P0001'
          AND erro_mensagem = 'falha controlada ao persistir alerta'
    ) OR EXISTS (SELECT 1 FROM tcc_pld.alerta) THEN
        RAISE EXCEPTION 'Registro de falha da R01 nao foi preservado';
    END IF;
    RAISE NOTICE 'REGISTRO DE FALHA PASSOU';
END;
$$;

-- Interrompe a terceira evidencia depois de o alerta e duas evidencias entrarem
-- no bloco protegido. A sequencia temporaria permite verificar o ponto atingido.
CREATE TEMP SEQUENCE ordem_teste_evidencia;
CREATE FUNCTION pg_temp.interromper_evidencias()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF nextval('pg_temp.ordem_teste_evidencia') = 3 THEN
        RAISE EXCEPTION 'falha controlada na terceira evidencia';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER teste_interromper_evidencias
BEFORE INSERT ON tcc_pld.evidencia_alerta
FOR EACH ROW EXECUTE FUNCTION pg_temp.interromper_evidencias();

CALL tcc_pld.executar_r01('LEGADO_SEM_BASE');
DO $$
BEGIN
    IF (SELECT last_value FROM pg_temp.ordem_teste_evidencia) <> 3
       OR (SELECT count(*) FROM tcc_pld.execucao_monitoramento
           WHERE estado = 'FALHOU' AND erro_codigo = 'P0001'
             AND erro_mensagem = 'falha controlada na terceira evidencia'
             AND concluida_em IS NOT NULL) <> 1
       OR EXISTS (SELECT 1 FROM tcc_pld.alerta)
       OR EXISTS (SELECT 1 FROM tcc_pld.evidencia_alerta) THEN
        RAISE EXCEPTION 'Falha no descarte de registros parciais';
    END IF;
    RAISE NOTICE 'FALHA NA TERCEIRA EVIDENCIA PASSOU: zero alertas e zero evidencias parciais.';
END;
$$;

ROLLBACK;

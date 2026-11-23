-- Teste funcional da base: executar apos 001_BASE_TCC.sql, somente em desenvolvimento.
-- Nao e teste da regra R01, nem resultado experimental. Os dados sao revertidos.
BEGIN;

DO $$
DECLARE
    v_cliente bigint;
    v_conta bigint;
    v_transacao bigint;
    v_codigo text := 'TESTE_BASE_' || txid_current()::text;
    v_quantidade integer;
    v_fk_bloqueada boolean := false;
    v_valor_bloqueado boolean := false;
BEGIN
    INSERT INTO tcc_pld.cliente (codigo_sintetico, tipo)
    VALUES (v_codigo, 'PF') RETURNING cliente_id INTO v_cliente;

    INSERT INTO tcc_pld.conta (codigo_sintetico, cliente_id, data_abertura)
    VALUES (v_codigo, v_cliente, DATE '2026-01-01') RETURNING conta_id INTO v_conta;

    INSERT INTO tcc_pld.transacao
        (codigo_sintetico, conta_id, instante_evento, direcao, valor)
    VALUES
        (v_codigo, v_conta, TIMESTAMPTZ '2026-09-01 12:00:00-03', 'SAIDA', 100.00)
    RETURNING transacao_id INTO v_transacao;
    IF NOT EXISTS (
        SELECT 1 FROM tcc_pld.auditoria_transacao
        WHERE transacao_id = v_transacao AND operacao = 'INSERT'
          AND antes IS NULL AND (depois->>'valor')::numeric = 100
          AND ator_banco = session_user AND registrada_em IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'Falha na auditoria de INSERT';
    END IF;

    UPDATE tcc_pld.transacao SET valor = 120.00
    WHERE transacao_id = v_transacao;

    IF NOT EXISTS (
        SELECT 1 FROM tcc_pld.auditoria_transacao
        WHERE transacao_id = v_transacao AND operacao = 'UPDATE'
          AND (antes->>'valor')::numeric = 100
          AND (depois->>'valor')::numeric = 120
    ) THEN
        RAISE EXCEPTION 'Falha nos valores antes/depois de UPDATE';
    END IF;

    BEGIN
        INSERT INTO tcc_pld.transacao
            (codigo_sintetico, conta_id, instante_evento, direcao, valor)
        VALUES
            (v_codigo || '_FK', -1, TIMESTAMPTZ '2026-09-01 12:01:00-03', 'SAIDA', 1);
    EXCEPTION WHEN foreign_key_violation THEN
        v_fk_bloqueada := true;
    END;

    IF NOT v_fk_bloqueada THEN
        RAISE EXCEPTION 'FK nao bloqueou conta inexistente';
    END IF;

    BEGIN
        INSERT INTO tcc_pld.transacao
            (codigo_sintetico, conta_id, instante_evento, direcao, valor)
        VALUES
            (v_codigo || '_VALOR', v_conta, TIMESTAMPTZ '2026-09-01 12:01:00-03', 'SAIDA', -1);
    EXCEPTION WHEN check_violation THEN
        v_valor_bloqueado := true;
    END;

    IF NOT v_valor_bloqueado THEN
        RAISE EXCEPTION 'Valor negativo aceito';
    END IF;

    DELETE FROM tcc_pld.transacao
    WHERE transacao_id = v_transacao;

    IF NOT EXISTS (
        SELECT 1 FROM tcc_pld.auditoria_transacao
        WHERE transacao_id = v_transacao AND operacao = 'DELETE'
          AND (antes->>'valor')::numeric = 120 AND depois IS NULL
    ) THEN
        RAISE EXCEPTION 'Falha na auditoria de DELETE';
    END IF;

    SELECT count(*) INTO v_quantidade
    FROM tcc_pld.auditoria_transacao
    WHERE transacao_id = v_transacao;

    IF v_quantidade <> 3 THEN
        RAISE EXCEPTION 'Quantidade de registros de auditoria inesperada';
    END IF;

    IF EXISTS (
        SELECT 1 FROM tcc_pld.transacao WHERE transacao_id = v_transacao
    ) THEN
        RAISE EXCEPTION 'Transacao permaneceu apos DELETE';
    END IF;

    RAISE NOTICE 'PASSOU: INSERT, UPDATE, DELETE, snapshots, ator, FK e valor positivo.';
END;
$$;

ROLLBACK;

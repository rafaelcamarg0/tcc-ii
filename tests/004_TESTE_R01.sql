\set ON_ERROR_STOP on
-- Testes funcionais da R01. Dados sinteticos e transacao revertida ao final.
BEGIN;

CREATE FUNCTION pg_temp.nova_conta(p_codigo text)
RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
    v_cliente bigint;
    v_conta bigint;
BEGIN
    INSERT INTO tcc_pld.cliente (codigo_sintetico, tipo)
    VALUES (p_codigo || '_CLI', 'PF')
    RETURNING cliente_id INTO v_cliente;

    INSERT INTO tcc_pld.conta
        (codigo_sintetico, cliente_id, data_abertura)
    VALUES
        (p_codigo || '_CTA', v_cliente, DATE '2026-01-01')
    RETURNING conta_id INTO v_conta;

    RETURN v_conta;
END;
$$;

CREATE PROCEDURE pg_temp.limpar()
LANGUAGE plpgsql
AS $$
BEGIN
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
END;
$$;

CREATE PROCEDURE pg_temp.exigir_conclusao(p_quantidade integer DEFAULT 1)
LANGUAGE plpgsql
AS $$
BEGIN
    IF (SELECT count(*) FROM tcc_pld.execucao_monitoramento)
            <> p_quantidade
       OR (SELECT count(*) FROM tcc_pld.execucao_monitoramento
           WHERE estado = 'CONCLUIDA') <> p_quantidade THEN
        RAISE EXCEPTION 'Execucao da R01 nao foi concluida';
    END IF;
END;
$$;

-- C01: quatro saidas nao atingem o limiar.
DO $$
DECLARE v_conta bigint;
BEGIN
    CALL pg_temp.limpar();
    v_conta := pg_temp.nova_conta('C01');
    INSERT INTO tcc_pld.transacao
        (codigo_sintetico, conta_id, instante_evento, direcao, valor)
    SELECT 'C01_' || i, v_conta,
           TIMESTAMPTZ '2026-09-01 12:00:00-03' + i * interval '1 minute',
           'SAIDA', 100
    FROM generate_series(0, 3) AS g(i);
    CALL tcc_pld.executar_r01('LEGADO_SEM_BASE');
    CALL pg_temp.exigir_conclusao();
    IF (SELECT count(*) FROM tcc_pld.alerta) <> 0 THEN
        RAISE EXCEPTION 'C01 falhou';
    END IF;
    RAISE NOTICE 'C01 PASSOU';
END;
$$;

-- C02: exatamente cinco saidas geram um alerta.
DO $$
DECLARE v_conta bigint;
BEGIN
    CALL pg_temp.limpar();
    v_conta := pg_temp.nova_conta('C02');
    INSERT INTO tcc_pld.transacao
        (codigo_sintetico, conta_id, instante_evento, direcao, valor)
    SELECT 'C02_' || i, v_conta,
           TIMESTAMPTZ '2026-09-01 12:00:00-03' + i * interval '1 minute',
           'SAIDA', 100
    FROM generate_series(0, 4) AS g(i);

    CALL tcc_pld.executar_r01('LEGADO_SEM_BASE');
    CALL pg_temp.exigir_conclusao();
    IF (SELECT count(*) FROM tcc_pld.alerta) <> 1
       OR (SELECT (resultado_observado->>'quantidade')::integer
           FROM tcc_pld.alerta) <> 5 THEN
        RAISE EXCEPTION 'C02 falhou';
    END IF;
    RAISE NOTICE 'C02 PASSOU';
END;
$$;

-- C03: seis saidas geram alertas nas referencias 12:04 e 12:05.
DO $$
DECLARE v_conta bigint;
BEGIN
    CALL pg_temp.limpar();
    v_conta := pg_temp.nova_conta('C03');
    INSERT INTO tcc_pld.transacao
        (codigo_sintetico, conta_id, instante_evento, direcao, valor)
    SELECT 'C03_' || i, v_conta,
           TIMESTAMPTZ '2026-09-01 12:00:00-03' + i * interval '1 minute',
           'SAIDA', 100
    FROM generate_series(0, 5) AS g(i);

    CALL tcc_pld.executar_r01('LEGADO_SEM_BASE');
    CALL pg_temp.exigir_conclusao();
    IF (SELECT count(*) FROM tcc_pld.alerta) <> 2 THEN
        RAISE EXCEPTION 'C03 falhou';
    END IF;
    RAISE NOTICE 'C03 PASSOU';
END;
$$;

-- C04: o limite inferior e aberto; 12:00 nao entra na janela de 12:10.
DO $$
DECLARE v_conta bigint;
BEGIN
    CALL pg_temp.limpar();
    v_conta := pg_temp.nova_conta('C04');
    INSERT INTO tcc_pld.transacao
        (codigo_sintetico, conta_id, instante_evento, direcao, valor)
    SELECT 'C04_' || row_number() OVER (), v_conta, instante, 'SAIDA', 100
    FROM (VALUES
        (TIMESTAMPTZ '2026-09-01 12:00:00-03'),
        (TIMESTAMPTZ '2026-09-01 12:07:00-03'),
        (TIMESTAMPTZ '2026-09-01 12:08:00-03'),
        (TIMESTAMPTZ '2026-09-01 12:09:00-03'),
        (TIMESTAMPTZ '2026-09-01 12:10:00-03')
    ) AS v(instante);

    CALL tcc_pld.executar_r01('LEGADO_SEM_BASE');
    CALL pg_temp.exigir_conclusao();
    IF (SELECT count(*) FROM tcc_pld.alerta) <> 0 THEN
        RAISE EXCEPTION 'C04 falhou';
    END IF;
    RAISE NOTICE 'C04 PASSOU';
END;
$$;

-- C05: 12:00:01 fica dentro da janela encerrada em 12:10.
DO $$
DECLARE v_conta bigint;
BEGIN
    CALL pg_temp.limpar();
    v_conta := pg_temp.nova_conta('C05');
    INSERT INTO tcc_pld.transacao
        (codigo_sintetico, conta_id, instante_evento, direcao, valor)
    SELECT 'C05_' || row_number() OVER (), v_conta, instante, 'SAIDA', 100
    FROM (VALUES
        (TIMESTAMPTZ '2026-09-01 12:00:01-03'),
        (TIMESTAMPTZ '2026-09-01 12:07:00-03'),
        (TIMESTAMPTZ '2026-09-01 12:08:00-03'),
        (TIMESTAMPTZ '2026-09-01 12:09:00-03'),
        (TIMESTAMPTZ '2026-09-01 12:10:00-03')
    ) AS v(instante);

    CALL tcc_pld.executar_r01('LEGADO_SEM_BASE');
    CALL pg_temp.exigir_conclusao();
    IF (SELECT count(*) FROM tcc_pld.alerta) <> 1 THEN
        RAISE EXCEPTION 'C05 falhou';
    END IF;
    RAISE NOTICE 'C05 PASSOU';
END;
$$;

-- C06: entradas nao participam da contagem.
DO $$
DECLARE v_conta bigint;
BEGIN
    CALL pg_temp.limpar();
    v_conta := pg_temp.nova_conta('C06');
    INSERT INTO tcc_pld.transacao
        (codigo_sintetico, conta_id, instante_evento, direcao, valor)
    SELECT 'C06_S_' || i, v_conta,
           TIMESTAMPTZ '2026-09-01 12:00:00-03' + i * interval '1 minute',
           'SAIDA', 100
    FROM generate_series(0, 3) AS g(i);
    INSERT INTO tcc_pld.transacao
        (codigo_sintetico, conta_id, instante_evento, direcao, valor)
    VALUES
        ('C06_E', v_conta, TIMESTAMPTZ '2026-09-01 12:04:00-03', 'ENTRADA', 100);

    CALL tcc_pld.executar_r01('LEGADO_SEM_BASE');
    CALL pg_temp.exigir_conclusao();
    IF (SELECT count(*) FROM tcc_pld.alerta) <> 0 THEN
        RAISE EXCEPTION 'C06 falhou';
    END IF;
    RAISE NOTICE 'C06 PASSOU';
END;
$$;

-- C07: contas diferentes nao sao agregadas.
DO $$
DECLARE v_conta_a bigint; v_conta_b bigint;
BEGIN
    CALL pg_temp.limpar();
    v_conta_a := pg_temp.nova_conta('C07A');
    v_conta_b := pg_temp.nova_conta('C07B');

    INSERT INTO tcc_pld.transacao
        (codigo_sintetico, conta_id, instante_evento, direcao, valor)
    SELECT 'C07A_' || i, v_conta_a,
           TIMESTAMPTZ '2026-09-01 12:00:00-03' + i * interval '1 minute',
           'SAIDA', 100
    FROM generate_series(0, 2) AS g(i);
    INSERT INTO tcc_pld.transacao
        (codigo_sintetico, conta_id, instante_evento, direcao, valor)
    SELECT 'C07B_' || i, v_conta_b,
           TIMESTAMPTZ '2026-09-01 12:00:00-03' + i * interval '1 minute',
           'SAIDA', 100
    FROM generate_series(0, 1) AS g(i);

    CALL tcc_pld.executar_r01('LEGADO_SEM_BASE');
    CALL pg_temp.exigir_conclusao();
    IF (SELECT count(*) FROM tcc_pld.alerta) <> 0 THEN
        RAISE EXCEPTION 'C07 falhou';
    END IF;
    RAISE NOTICE 'C07 PASSOU';
END;
$$;

-- C08: cinco eventos simultaneos geram cinco alertas nesta politica inicial.
DO $$
DECLARE v_conta bigint;
BEGIN
    CALL pg_temp.limpar();
    v_conta := pg_temp.nova_conta('C08');
    INSERT INTO tcc_pld.transacao
        (codigo_sintetico, conta_id, instante_evento, direcao, valor)
    SELECT 'C08_' || i, v_conta,
           TIMESTAMPTZ '2026-09-01 12:00:00-03', 'SAIDA', 100
    FROM generate_series(1, 5) AS g(i);

    CALL tcc_pld.executar_r01('LEGADO_SEM_BASE');
    CALL pg_temp.exigir_conclusao();
    IF (SELECT count(*) FROM tcc_pld.alerta) <> 5 THEN
        RAISE EXCEPTION 'C08 falhou';
    END IF;
    RAISE NOTICE 'C08 PASSOU';
END;
$$;

-- C09: a ordem de insercao nao altera o resultado.
DO $$
DECLARE v_conta bigint;
BEGIN
    CALL pg_temp.limpar();
    v_conta := pg_temp.nova_conta('C09');
    INSERT INTO tcc_pld.transacao
        (codigo_sintetico, conta_id, instante_evento, direcao, valor)
    SELECT 'C09_' || i, v_conta,
           TIMESTAMPTZ '2026-09-01 12:00:00-03' + i * interval '1 minute',
           'SAIDA', 100
    FROM generate_series(4, 0, -1) AS g(i);

    CALL tcc_pld.executar_r01('LEGADO_SEM_BASE');
    CALL pg_temp.exigir_conclusao();
    IF (SELECT count(*) FROM tcc_pld.alerta) <> 1 THEN
        RAISE EXCEPTION 'C09 falhou';
    END IF;
    RAISE NOTICE 'C09 PASSOU';
END;
$$;

-- C10: repetir a analise nao duplica alertas, mas registra duas execucoes.
DO $$
DECLARE v_conta bigint;
BEGIN
    CALL pg_temp.limpar();
    v_conta := pg_temp.nova_conta('C10');
    INSERT INTO tcc_pld.transacao
        (codigo_sintetico, conta_id, instante_evento, direcao, valor)
    SELECT 'C10_' || i, v_conta,
           TIMESTAMPTZ '2026-09-01 12:00:00-03' + i * interval '1 minute',
           'SAIDA', 100
    FROM generate_series(0, 4) AS g(i);

    CALL tcc_pld.executar_r01('LEGADO_SEM_BASE');
    CALL tcc_pld.executar_r01('LEGADO_SEM_BASE');
    CALL pg_temp.exigir_conclusao(2);
    IF (SELECT count(*) FROM tcc_pld.alerta) <> 1
       OR (SELECT count(*) FROM tcc_pld.execucao_monitoramento) <> 2 THEN
        RAISE EXCEPTION 'C10 falhou';
    END IF;
    RAISE NOTICE 'C10 PASSOU';
END;
$$;

-- C11: o alerta preserva cinco evidencias e os parametros usados.
DO $$
DECLARE v_conta bigint;
BEGIN
    CALL pg_temp.limpar();
    v_conta := pg_temp.nova_conta('C11');
    INSERT INTO tcc_pld.transacao
        (codigo_sintetico, conta_id, instante_evento, direcao, valor)
    SELECT 'C11_' || i, v_conta,
           TIMESTAMPTZ '2026-09-01 12:00:00-03' + i * interval '1 minute',
           'SAIDA', 100
    FROM generate_series(0, 4) AS g(i);

    CALL tcc_pld.executar_r01('LEGADO_SEM_BASE');
    CALL pg_temp.exigir_conclusao();
    IF (SELECT count(*) FROM tcc_pld.evidencia_alerta) <> 5
       OR NOT EXISTS (
           SELECT 1 FROM tcc_pld.alerta
           WHERE parametros_utilizados @> '{"quantidade_minima": 5}'::jsonb
             AND resultado_observado ? 'janela_inicio_exclusiva'
             AND resultado_observado ? 'janela_fim_inclusiva'
       ) THEN
        RAISE EXCEPTION 'C11 falhou';
    END IF;
    RAISE NOTICE 'C11 PASSOU';
END;
$$;

-- C12: insercao, alteracao e exclusao deixam tres registros de auditoria.
DO $$
DECLARE v_conta bigint; v_transacao bigint;
BEGIN
    CALL pg_temp.limpar();
    v_conta := pg_temp.nova_conta('C12');
    INSERT INTO tcc_pld.transacao
        (codigo_sintetico, conta_id, instante_evento, direcao, valor)
    VALUES
        ('C12_T', v_conta, TIMESTAMPTZ '2026-09-01 12:00:00-03', 'SAIDA', 100)
    RETURNING transacao_id INTO v_transacao;

    UPDATE tcc_pld.transacao SET valor = 120
    WHERE transacao_id = v_transacao;
    DELETE FROM tcc_pld.transacao
    WHERE transacao_id = v_transacao;

    IF (SELECT count(*) FROM tcc_pld.auditoria_transacao
        WHERE transacao_id = v_transacao) <> 3 THEN
        RAISE EXCEPTION 'C12 falhou';
    END IF;
    RAISE NOTICE 'C12 PASSOU';
END;
$$;

ROLLBACK;

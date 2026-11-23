\set ON_ERROR_STOP on
-- Valida contagens, unicidade e reproducibilidade do gerador.
BEGIN;

DO $$
DECLARE
    v_hash_primeira text;
    v_hash_segunda text;
    v_repeticao_bloqueada boolean := false;
    v_reservado_bloqueado boolean := false;
BEGIN
    BEGIN
        CALL tcc_pld.gerar_base_sintetica(
            'LEGADO_SEM_BASE', 1, 1, 12345
        );
    EXCEPTION WHEN OTHERS THEN
        v_reservado_bloqueado := SQLERRM =
            'O identificador LEGADO_SEM_BASE e reservado';
    END;

    IF NOT v_reservado_bloqueado THEN
        RAISE EXCEPTION 'Identificador reservado foi aceito pelo gerador';
    END IF;

    CALL tcc_pld.gerar_base_sintetica(
        'TESTE_GERADOR',
        10,
        100,
        12345,
        TIMESTAMPTZ '2026-01-01 00:00:00-03',
        TIMESTAMPTZ '2026-02-01 00:00:00-03'
    );

    IF (SELECT count(*) FROM tcc_pld.cliente
        WHERE codigo_sintetico LIKE 'TESTE_GERADOR_CLI_%') <> 10 THEN
        RAISE EXCEPTION 'Quantidade de clientes incorreta';
    END IF;
    IF (SELECT count(*) FROM tcc_pld.conta
        WHERE codigo_sintetico LIKE 'TESTE_GERADOR_CONTA_%') <> 10 THEN
        RAISE EXCEPTION 'Quantidade de contas incorreta';
    END IF;
    IF (SELECT count(*) FROM tcc_pld.transacao
        WHERE codigo_sintetico LIKE 'TESTE_GERADOR_TX_%') <> 100 THEN
        RAISE EXCEPTION 'Quantidade de transacoes incorreta';
    END IF;

    BEGIN
        CALL tcc_pld.gerar_base_sintetica(
            'TESTE_GERADOR', 10, 100, 12345
        );
    EXCEPTION WHEN unique_violation THEN
        v_repeticao_bloqueada := true;
    END;

    IF NOT v_repeticao_bloqueada THEN
        RAISE EXCEPTION 'Identificador duplicado foi aceito';
    END IF;

    SELECT md5(string_agg(
        transacao.codigo_sintetico || '|' ||
        conta.codigo_sintetico || '|' ||
        transacao.instante_evento::text || '|' ||
        transacao.direcao || '|' ||
        transacao.valor::text,
        E'\n' ORDER BY transacao.codigo_sintetico
    ))
    INTO v_hash_primeira
    FROM tcc_pld.transacao AS transacao
    JOIN tcc_pld.conta AS conta USING (conta_id)
    WHERE transacao.codigo_sintetico LIKE 'TESTE_GERADOR_TX_%';

    DELETE FROM tcc_pld.transacao
    WHERE codigo_sintetico LIKE 'TESTE_GERADOR_TX_%';
    DELETE FROM tcc_pld.conta
    WHERE codigo_sintetico LIKE 'TESTE_GERADOR_CONTA_%';
    DELETE FROM tcc_pld.cliente
    WHERE codigo_sintetico LIKE 'TESTE_GERADOR_CLI_%';
    DELETE FROM tcc_pld.base_sintetica
    WHERE identificador = 'TESTE_GERADOR';

    CALL tcc_pld.gerar_base_sintetica(
        'TESTE_GERADOR',
        10,
        100,
        12345,
        TIMESTAMPTZ '2026-01-01 00:00:00-03',
        TIMESTAMPTZ '2026-02-01 00:00:00-03'
    );

    SELECT md5(string_agg(
        transacao.codigo_sintetico || '|' ||
        conta.codigo_sintetico || '|' ||
        transacao.instante_evento::text || '|' ||
        transacao.direcao || '|' ||
        transacao.valor::text,
        E'\n' ORDER BY transacao.codigo_sintetico
    ))
    INTO v_hash_segunda
    FROM tcc_pld.transacao AS transacao
    JOIN tcc_pld.conta AS conta USING (conta_id)
    WHERE transacao.codigo_sintetico LIKE 'TESTE_GERADOR_TX_%';

    IF v_hash_primeira IS DISTINCT FROM v_hash_segunda THEN
        RAISE EXCEPTION 'A base nao foi reproduzida com os mesmos parametros';
    END IF;

    RAISE NOTICE
        'PASSOU: contagens, duplicidade e reproducibilidade. Hash=%',
        v_hash_segunda;
END;
$$;

ROLLBACK;

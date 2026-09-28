-- Gerador reproduzivel para testes de volume.
-- Nao utiliza nem imita dados de pessoas reais.

CREATE TABLE IF NOT EXISTS tcc_pld.base_sintetica (
    base_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    identificador text NOT NULL UNIQUE,
    semente bigint NOT NULL,
    quantidade_clientes integer NOT NULL CHECK (quantidade_clientes > 0),
    quantidade_transacoes bigint NOT NULL CHECK (quantidade_transacoes >= 0),
    periodo_inicio timestamptz NOT NULL,
    periodo_fim timestamptz NOT NULL,
    gerada_em timestamptz NOT NULL DEFAULT clock_timestamp(),
    CHECK (periodo_fim > periodo_inicio)
);

CREATE OR REPLACE PROCEDURE tcc_pld.gerar_base_sintetica(
    p_identificador text,
    p_quantidade_clientes integer,
    p_quantidade_transacoes bigint,
    p_semente bigint DEFAULT 20260928,
    p_periodo_inicio timestamptz DEFAULT TIMESTAMPTZ '2026-01-01 00:00:00-03',
    p_periodo_fim timestamptz DEFAULT TIMESTAMPTZ '2026-02-01 00:00:00-03'
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_identificador IS NULL OR btrim(p_identificador) = '' THEN
        RAISE EXCEPTION 'O identificador da base e obrigatorio';
    END IF;
    IF p_quantidade_clientes < 1 THEN
        RAISE EXCEPTION 'A quantidade de clientes deve ser positiva';
    END IF;
    IF p_quantidade_transacoes < 0 THEN
        RAISE EXCEPTION 'A quantidade de transacoes nao pode ser negativa';
    END IF;
    IF p_periodo_fim <= p_periodo_inicio THEN
        RAISE EXCEPTION 'O periodo final deve ser posterior ao inicial';
    END IF;

    INSERT INTO tcc_pld.base_sintetica (
        identificador,
        semente,
        quantidade_clientes,
        quantidade_transacoes,
        periodo_inicio,
        periodo_fim
    )
    VALUES (
        p_identificador,
        p_semente,
        p_quantidade_clientes,
        p_quantidade_transacoes,
        p_periodo_inicio,
        p_periodo_fim
    );

    INSERT INTO tcc_pld.cliente (
        codigo_sintetico,
        tipo,
        renda_min,
        renda_max,
        movimentacao_mensal_esperada
    )
    SELECT
        p_identificador || '_CLI_' || serie,
        CASE WHEN serie % 5 = 0 THEN 'PJ' ELSE 'PF' END,
        1000 + (serie % 20) * 500,
        1500 + (serie % 20) * 500,
        2000 + (serie % 30) * 1000
    FROM generate_series(1, p_quantidade_clientes) AS g(serie);

    INSERT INTO tcc_pld.conta (
        codigo_sintetico,
        cliente_id,
        data_abertura
    )
    SELECT
        p_identificador || '_CONTA_' || serie,
        cliente.cliente_id,
        DATE '2025-01-01' + ((serie - 1) % 365)
    FROM generate_series(1, p_quantidade_clientes) AS g(serie)
    JOIN tcc_pld.cliente AS cliente
      ON cliente.codigo_sintetico = p_identificador || '_CLI_' || serie;

    INSERT INTO tcc_pld.transacao (
        codigo_sintetico,
        conta_id,
        instante_evento,
        direcao,
        valor
    )
    SELECT
        p_identificador || '_TX_' || serie,
        conta.conta_id,
        p_periodo_inicio
            + (
                (
                    hashtextextended(
                        p_identificador || ':' || serie || ':tempo',
                        p_semente
                    ) & 9223372036854775807
                ) % extract(epoch FROM (p_periodo_fim - p_periodo_inicio))::bigint
              ) * interval '1 second',
        CASE
            WHEN (
                hashtextextended(
                    p_identificador || ':' || serie || ':direcao',
                    p_semente
                ) & 9223372036854775807
            ) % 100 < 45 THEN 'ENTRADA'
            ELSE 'SAIDA'
        END,
        (
            100
            + (
                hashtextextended(
                    p_identificador || ':' || serie || ':valor',
                    p_semente
                ) & 9223372036854775807
              ) % 500000
        )::numeric / 100
    FROM generate_series(1, p_quantidade_transacoes) AS g(serie)
    JOIN tcc_pld.conta AS conta
      ON conta.codigo_sintetico =
         p_identificador || '_CONTA_' ||
         (((serie - 1) % p_quantidade_clientes) + 1);
END;
$$;

COMMENT ON PROCEDURE tcc_pld.gerar_base_sintetica(
    text, integer, bigint, bigint, timestamptz, timestamptz
) IS
    'Gera clientes, contas e transacoes sinteticas reproduziveis para testes de volume.';

-- Cenarios positivos controlados para a R01.
-- Representam somente o padrao da regra, nao lavagem de dinheiro real.

CREATE TABLE IF NOT EXISTS tcc_pld.cenario_r01 (
    cenario_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    identificador_base text NOT NULL
        REFERENCES tcc_pld.base_sintetica (identificador),
    codigo_cenario text NOT NULL UNIQUE,
    conta_id bigint NOT NULL REFERENCES tcc_pld.conta,
    transacao_referencia_id bigint NOT NULL REFERENCES tcc_pld.transacao,
    quantidade_eventos integer NOT NULL CHECK (quantidade_eventos = 5),
    alertas_esperados integer NOT NULL CHECK (alertas_esperados = 1),
    criado_em timestamptz NOT NULL DEFAULT clock_timestamp()
);

ALTER TABLE tcc_pld.cenario_r01
    DROP CONSTRAINT IF EXISTS cenario_r01_quantidade_eventos_check,
    DROP CONSTRAINT IF EXISTS cenario_r01_alertas_esperados_check,
    ADD CONSTRAINT cenario_r01_quantidade_eventos_check CHECK (quantidade_eventos = 5),
    ADD CONSTRAINT cenario_r01_alertas_esperados_check CHECK (alertas_esperados = 1);

CREATE OR REPLACE PROCEDURE tcc_pld.injetar_cenarios_r01(
    p_identificador_base text,
    p_quantidade_cenarios integer,
    p_eventos_por_cenario integer DEFAULT 5,
    p_inicio timestamptz DEFAULT TIMESTAMPTZ '2026-01-15 12:00:00-03'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cenario integer;
    v_cliente_id bigint;
    v_conta_id bigint;
    v_referencia_id bigint;
    v_codigo text;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM tcc_pld.base_sintetica
        WHERE identificador = p_identificador_base
    ) THEN
        RAISE EXCEPTION 'Base sintetica % nao encontrada', p_identificador_base;
    END IF;
    IF p_quantidade_cenarios < 1 THEN
        RAISE EXCEPTION 'A quantidade de cenarios deve ser positiva';
    END IF;
    IF p_eventos_por_cenario <> 5 THEN
        RAISE EXCEPTION 'A versao controlada exige exatamente 5 eventos por cenario';
    END IF;

    FOR v_cenario IN 1..p_quantidade_cenarios LOOP
        v_codigo := p_identificador_base || '_R01_POS_' || v_cenario;

        INSERT INTO tcc_pld.cliente (
            codigo_sintetico,
            tipo,
            renda_min,
            renda_max,
            movimentacao_mensal_esperada
        )
        VALUES (
            v_codigo || '_CLI', 'PF', 2000, 3000, 5000
        )
        RETURNING cliente_id INTO v_cliente_id;

        INSERT INTO tcc_pld.conta (
            codigo_sintetico,
            cliente_id,
            data_abertura
        )
        VALUES (
            v_codigo || '_CONTA', v_cliente_id, DATE '2025-01-01'
        )
        RETURNING conta_id INTO v_conta_id;

        INSERT INTO tcc_pld.transacao (
            codigo_sintetico,
            conta_id,
            instante_evento,
            direcao,
            valor
        )
        SELECT
            v_codigo || '_TX_' || evento,
            v_conta_id,
            p_inicio + (evento - 1) * interval '1 minute',
            'SAIDA',
            100
        FROM generate_series(1, p_eventos_por_cenario) AS g(evento);

        SELECT transacao_id
        INTO v_referencia_id
        FROM tcc_pld.transacao
        WHERE codigo_sintetico =
            v_codigo || '_TX_' || p_eventos_por_cenario;
        INSERT INTO tcc_pld.cenario_r01 (
            identificador_base,
            codigo_cenario,
            conta_id,
            transacao_referencia_id,
            quantidade_eventos,
            alertas_esperados
        )
        VALUES (
            p_identificador_base,
            v_codigo,
            v_conta_id,
            v_referencia_id,
            p_eventos_por_cenario,
            1
        );
    END LOOP;
END;
$$;

COMMENT ON TABLE tcc_pld.cenario_r01 IS
    'Ground truth de cenarios construidos para validar a regra R01.';
COMMENT ON PROCEDURE tcc_pld.injetar_cenarios_r01(
    text, integer, integer, timestamptz
) IS
    'Injeta contas exclusivas com cinco ou mais saidas em minutos consecutivos.';

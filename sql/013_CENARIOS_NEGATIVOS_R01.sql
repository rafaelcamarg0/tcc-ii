-- Cenarios negativos controlados para a R01.
-- Sao casos proximos do limiar que nao devem gerar alerta.

CREATE TABLE IF NOT EXISTS tcc_pld.cenario_negativo_r01 (
    cenario_negativo_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    identificador_base text NOT NULL
        REFERENCES tcc_pld.base_sintetica (identificador),
    codigo_cenario text NOT NULL UNIQUE,
    tipo text NOT NULL CHECK (
        tipo IN (
            'ABAIXO_LIMIAR',
            'FORA_JANELA',
            'DIRECAO_MISTA',
            'CONTAS_SEPARADAS'
        )
    ),
    cliente_id bigint NOT NULL REFERENCES tcc_pld.cliente,
    alertas_esperados integer NOT NULL DEFAULT 0
        CHECK (alertas_esperados = 0),
    criado_em timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE OR REPLACE PROCEDURE tcc_pld.injetar_cenarios_negativos_r01(
    p_identificador_base text,
    p_quantidade_por_tipo integer DEFAULT 1,
    p_inicio timestamptz DEFAULT TIMESTAMPTZ '2026-01-20 12:00:00-03'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_indice integer;
    v_tipo text;
    v_codigo text;
    v_cliente_id bigint;
    v_conta_a bigint;
    v_conta_b bigint;
    v_inicio_cenario timestamptz;
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM tcc_pld.base_sintetica
        WHERE identificador = p_identificador_base
    ) THEN
        RAISE EXCEPTION
            'Base sintetica % nao encontrada',
            p_identificador_base;
    END IF;

    IF p_quantidade_por_tipo < 1 THEN
        RAISE EXCEPTION
            'A quantidade por tipo deve ser positiva';
    END IF;

    FOR v_indice IN 1..p_quantidade_por_tipo LOOP
        FOREACH v_tipo IN ARRAY ARRAY[
            'ABAIXO_LIMIAR',
            'FORA_JANELA',
            'DIRECAO_MISTA',
            'CONTAS_SEPARADAS'
        ] LOOP
            v_codigo :=
                p_identificador_base || '_R01_NEG_' ||
                v_tipo || '_' || v_indice;
            v_inicio_cenario :=
                p_inicio + (v_indice - 1) * interval '1 hour';

            INSERT INTO tcc_pld.cliente (
                codigo_sintetico,
                tipo,
                renda_min,
                renda_max,
                movimentacao_mensal_esperada
            )
            VALUES (
                v_codigo || '_CLI',
                'PF',
                2000,
                3000,
                5000
            )
            RETURNING cliente_id INTO v_cliente_id;

            INSERT INTO tcc_pld.conta (
                codigo_sintetico,
                cliente_id,
                data_abertura
            )
            VALUES (
                v_codigo || '_CONTA_A',
                v_cliente_id,
                DATE '2025-01-01'
            )
            RETURNING conta_id INTO v_conta_a;

            IF v_tipo = 'CONTAS_SEPARADAS' THEN
                INSERT INTO tcc_pld.conta (
                    codigo_sintetico,
                    cliente_id,
                    data_abertura
                )
                VALUES (
                    v_codigo || '_CONTA_B',
                    v_cliente_id,
                    DATE '2025-01-01'
                )
                RETURNING conta_id INTO v_conta_b;

                INSERT INTO tcc_pld.transacao (
                    codigo_sintetico,
                    conta_id,
                    instante_evento,
                    direcao,
                    valor
                )
                SELECT
                    v_codigo || '_A_TX_' || evento,
                    v_conta_a,
                    v_inicio_cenario
                        + (evento - 1) * interval '1 minute',
                    'SAIDA',
                    100
                FROM generate_series(1, 3) AS g(evento);

                INSERT INTO tcc_pld.transacao (
                    codigo_sintetico,
                    conta_id,
                    instante_evento,
                    direcao,
                    valor
                )
                SELECT
                    v_codigo || '_B_TX_' || evento,
                    v_conta_b,
                    v_inicio_cenario
                        + (evento - 1) * interval '1 minute',
                    'SAIDA',
                    100
                FROM generate_series(1, 2) AS g(evento);

            ELSIF v_tipo = 'ABAIXO_LIMIAR' THEN
                INSERT INTO tcc_pld.transacao (
                    codigo_sintetico,
                    conta_id,
                    instante_evento,
                    direcao,
                    valor
                )
                SELECT
                    v_codigo || '_TX_' || evento,
                    v_conta_a,
                    v_inicio_cenario
                        + (evento - 1) * interval '1 minute',
                    'SAIDA',
                    100
                FROM generate_series(1, 4) AS g(evento);

            ELSIF v_tipo = 'FORA_JANELA' THEN
                INSERT INTO tcc_pld.transacao (
                    codigo_sintetico,
                    conta_id,
                    instante_evento,
                    direcao,
                    valor
                )
                SELECT
                    v_codigo || '_TX_' || evento,
                    v_conta_a,
                    v_inicio_cenario
                        + (evento - 1) * interval '3 minutes',
                    'SAIDA',
                    100
                FROM generate_series(1, 5) AS g(evento);

            ELSE
                INSERT INTO tcc_pld.transacao (
                    codigo_sintetico,
                    conta_id,
                    instante_evento,
                    direcao,
                    valor
                )
                SELECT
                    v_codigo || '_TX_' || evento,
                    v_conta_a,
                    v_inicio_cenario
                        + (evento - 1) * interval '1 minute',
                    CASE
                        WHEN evento = 3 THEN 'ENTRADA'
                        ELSE 'SAIDA'
                    END,
                    100
                FROM generate_series(1, 5) AS g(evento);
            END IF;

            INSERT INTO tcc_pld.cenario_negativo_r01 (
                identificador_base,
                codigo_cenario,
                tipo,
                cliente_id,
                alertas_esperados
            )
            VALUES (
                p_identificador_base,
                v_codigo,
                v_tipo,
                v_cliente_id,
                0
            );
        END LOOP;
    END LOOP;
END;
$$;

COMMENT ON TABLE tcc_pld.cenario_negativo_r01 IS
    'Ground truth negativo de casos proximos ao limiar da R01.';

COMMENT ON PROCEDURE tcc_pld.injetar_cenarios_negativos_r01(
    text, integer, timestamptz
) IS
    'Injeta quatro tipos de cenario que nao devem disparar a R01.';

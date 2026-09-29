-- TCC II: proposta inicial para PostgreSQL. Apenas ambiente de desenvolvimento.
-- Execute uma vez em banco exclusivo. Se o esquema existir, a transacao falha.
-- Sem dados reais. Auditoria funcional, sem promessa de inviolabilidade.
BEGIN;

CREATE SCHEMA tcc_pld;

CREATE TABLE tcc_pld.cliente (
    cliente_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo_sintetico text NOT NULL UNIQUE,
    tipo text NOT NULL CHECK (tipo IN ('PF', 'PJ')),
    renda_min numeric(18,2) CHECK (renda_min >= 0),
    renda_max numeric(18,2) CHECK (renda_max >= renda_min),
    movimentacao_mensal_esperada numeric(18,2) CHECK (movimentacao_mensal_esperada >= 0),
    CHECK ((renda_min IS NULL) = (renda_max IS NULL))
);

CREATE TABLE tcc_pld.conta (
    conta_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo_sintetico text NOT NULL UNIQUE,
    cliente_id bigint NOT NULL REFERENCES tcc_pld.cliente,
    data_abertura date NOT NULL
);

-- Uma linha representa um movimento de uma conta, nao um lancamento contabil bancario.
-- Todos os valores deste recorte representam BRL; nao ha conversao cambial.
CREATE TABLE tcc_pld.transacao (
    transacao_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo_sintetico text NOT NULL UNIQUE,
    -- FK adicionada em 005, depois da criacao de base_sintetica.
    base_id bigint,
    conta_id bigint NOT NULL REFERENCES tcc_pld.conta,
    instante_evento timestamptz NOT NULL,
    direcao text NOT NULL CHECK (direcao IN ('ENTRADA', 'SAIDA')),
    valor numeric(18,2) NOT NULL CHECK (valor > 0),
    registrada_em timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX transacao_conta_instante_idx
    ON tcc_pld.transacao (conta_id, instante_evento);

CREATE TABLE tcc_pld.regra (
    codigo text NOT NULL,
    versao integer NOT NULL CHECK (versao > 0),
    descricao text NOT NULL,
    parametros jsonb NOT NULL CHECK (jsonb_typeof(parametros) = 'object'),
    PRIMARY KEY (codigo, versao)
);

CREATE TABLE tcc_pld.execucao_monitoramento (
    execucao_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    identificador_base text NOT NULL,
    regra_codigo text NOT NULL,
    regra_versao integer NOT NULL CHECK (regra_versao > 0),
    parametros_utilizados jsonb NOT NULL
        CHECK (jsonb_typeof(parametros_utilizados) = 'object'),
    iniciada_em timestamptz NOT NULL DEFAULT clock_timestamp(),
    concluida_em timestamptz,
    estado text NOT NULL CHECK (estado IN ('EM_EXECUCAO', 'CONCLUIDA', 'FALHOU')),
    erro_codigo text,
    erro_mensagem text,
    CHECK (concluida_em IS NULL OR concluida_em >= iniciada_em),
    CONSTRAINT execucao_regra_fk
        FOREIGN KEY (regra_codigo, regra_versao)
        REFERENCES tcc_pld.regra (codigo, versao),
    CONSTRAINT execucao_estado_detalhes_check CHECK (
        (estado = 'EM_EXECUCAO' AND concluida_em IS NULL
            AND erro_codigo IS NULL AND erro_mensagem IS NULL)
        OR (estado = 'CONCLUIDA' AND concluida_em IS NOT NULL
            AND erro_codigo IS NULL AND erro_mensagem IS NULL)
        OR (estado = 'FALHOU' AND concluida_em IS NOT NULL
            AND erro_codigo IS NOT NULL AND erro_mensagem IS NOT NULL)
    )
);
-- A granularidade do alerta proposta e uma referencia por regra/versao.
CREATE TABLE tcc_pld.alerta (
    alerta_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    regra_codigo text NOT NULL,
    regra_versao integer NOT NULL,
    execucao_id bigint NOT NULL REFERENCES tcc_pld.execucao_monitoramento,
    transacao_referencia_id bigint NOT NULL REFERENCES tcc_pld.transacao,
    gerado_em timestamptz NOT NULL DEFAULT clock_timestamp(),
    resultado_observado jsonb NOT NULL CHECK (jsonb_typeof(resultado_observado) = 'object'),
    parametros_utilizados jsonb NOT NULL CHECK (jsonb_typeof(parametros_utilizados) = 'object'),
    FOREIGN KEY (regra_codigo, regra_versao) REFERENCES tcc_pld.regra (codigo, versao),
    UNIQUE (regra_codigo, regra_versao, transacao_referencia_id)
);

CREATE TABLE tcc_pld.evidencia_alerta (
    alerta_id bigint NOT NULL REFERENCES tcc_pld.alerta,
    transacao_id bigint NOT NULL REFERENCES tcc_pld.transacao,
    registro_observado jsonb NOT NULL CHECK (jsonb_typeof(registro_observado) = 'object'),
    PRIMARY KEY (alerta_id, transacao_id)
);

CREATE TABLE tcc_pld.auditoria_transacao (
    auditoria_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Sem FK: preserva a identificacao mesmo depois da exclusao da transacao.
    transacao_id bigint NOT NULL,
    operacao text NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE')),
    registrada_em timestamptz NOT NULL DEFAULT clock_timestamp(),
    ator_banco text NOT NULL,
    antes jsonb,
    depois jsonb
);

CREATE FUNCTION tcc_pld.registrar_auditoria_transacao()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO tcc_pld.auditoria_transacao
            (transacao_id, operacao, ator_banco, depois)
        VALUES
            (NEW.transacao_id, TG_OP, session_user, to_jsonb(NEW));
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO tcc_pld.auditoria_transacao
            (transacao_id, operacao, ator_banco, antes, depois)
        VALUES
            (NEW.transacao_id, TG_OP, session_user, to_jsonb(OLD), to_jsonb(NEW));
    ELSE
        INSERT INTO tcc_pld.auditoria_transacao
            (transacao_id, operacao, ator_banco, antes)
        VALUES
            (OLD.transacao_id, TG_OP, session_user, to_jsonb(OLD));
    END IF;
    RETURN NULL; -- O retorno e ignorado em trigger AFTER por linha.
END;
$$;

CREATE TRIGGER auditar_transacao
AFTER INSERT OR UPDATE OR DELETE ON tcc_pld.transacao
FOR EACH ROW EXECUTE FUNCTION tcc_pld.registrar_auditoria_transacao();

COMMENT ON SCHEMA tcc_pld IS
    'Prototipo academico com dados sinteticos. Alertas nao comprovam lavagem de dinheiro.';
COMMENT ON COLUMN tcc_pld.auditoria_transacao.ator_banco IS
    'Usuario autenticado da sessao do banco; nao identifica automaticamente um usuario de aplicacao.';

COMMIT;

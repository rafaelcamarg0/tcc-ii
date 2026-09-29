# Arquitetura do protótipo

## Objetivo e limite

O protótipo demonstra mecanismos automatizados de auditoria e monitoramento transacional no PostgreSQL para apoiar análises de PLD/FT. Ele usa somente dados sintéticos e gera alertas técnicos para revisão; não classifica pessoas, não comprova ilícitos e não substitui controles institucionais.

A implementação atual é deliberadamente centrada no banco de dados. Não há API, interface gráfica, autenticação de aplicação, agendador ou integração com sistemas externos.

## Implantação

~~~mermaid
flowchart TD
    U["Pesquisador"] --> C["Docker Compose"]
    C --> P["PostgreSQL 17"]
    S["SQL de inicialização"] --> P
    T["Testes SQL"] --> P
    P --> V["Volume persistente"]
~~~

O Docker Desktop executa um contêiner PostgreSQL e publica a porta 5432 somente na interface local 127.0.0.1. Os diretórios sql/ e tests/ são montados como somente leitura. O volume nomeado tcc_pld_data preserva o banco entre reinicializações.

Os scripts 001, 003, 005 e 008 inicializam uma base nova em ordem. Alterar esses arquivos não migra automaticamente um volume já criado; mudanças posteriores precisam ser aplicadas explicitamente ou em uma base nova.

## Componentes lógicos

| Componente | Responsabilidade |
|---|---|
| Núcleo transacional | Representar clientes sintéticos, contas e movimentos |
| Auditoria | Registrar INSERT, UPDATE e DELETE por gatilho |
| Catálogo de regras | Versionar descrição e parâmetros da R01 |
| Execução | Registrar início, conclusão ou falha, identificador, regra, versão, parâmetros e erro técnico |
| Alertas e evidências | Persistir ocorrências e os movimentos que as sustentam |
| Gerador sintético | Produzir carga reproduzível sem dados reais |
| Cenários controlados | Criar ground truth positivo e negativo restrito à lógica da R01 |
| Testes e benchmarks | Verificar comportamento e medir tempos controlados |
## Modelo de dados

~~~mermaid
erDiagram
    CLIENTE ||--o{ CONTA : possui
    CONTA ||--o{ TRANSACAO : registra
    BASE_SINTETICA ||--o{ TRANSACAO : delimita
    REGRA ||--o{ ALERTA : classifica
    EXECUCAO_MONITORAMENTO ||--o{ ALERTA : produz
    TRANSACAO ||--o{ ALERTA : referencia
    ALERTA ||--o{ EVIDENCIA_ALERTA : agrega
    TRANSACAO ||--o{ EVIDENCIA_ALERTA : fundamenta
    BASE_SINTETICA ||--o{ CENARIO_R01 : identifica
    BASE_SINTETICA ||--o{ CENARIO_NEGATIVO_R01 : identifica
    CLIENTE ||--o{ CENARIO_NEGATIVO_R01 : agrupa
    CONTA ||--o{ CENARIO_R01 : isola
    TRANSACAO ||--o{ CENARIO_R01 : referencia
~~~

A auditoria é desacoplada por projeto: auditoria_transacao.transacao_id não possui chave estrangeira. Assim, o identificador e o snapshot anterior permanecem após uma exclusão. Essa escolha preserva rastreabilidade funcional, mas não oferece imutabilidade criptográfica.

O índice transacao_conta_instante_idx (conta_id, instante_evento) atende a busca temporal por conta usada pela R01.

## Fluxo de auditoria

~~~mermaid
sequenceDiagram
    participant O as Operação SQL
    participant T as transacao
    participant G as Trigger AFTER
    participant A as auditoria_transacao
    O->>T: INSERT, UPDATE ou DELETE
    T->>G: uma chamada por linha
    G->>A: operação, ator e snapshots JSON
~~~

Em INSERT, grava-se o estado posterior; em UPDATE, os estados anterior e posterior; em DELETE, o estado anterior. session_user identifica o usuário do banco, não necessariamente uma pessoa da aplicação.
## Fluxo da R01

A procedure executar_r01 recebe identificador da base, quantidade mínima, janela e versão. O identificador normal deve corresponder a uma base sintética cadastrada, e somente as transações associadas a ela são processadas. O identificador reservado LEGADO_SEM_BASE permite testes manuais sobre registros antigos sem base_id. Na configuração atual, a procedure procura saídas da mesma conta em (T - W, T]; com os padrões de desenvolvimento, são cinco saídas em dez minutos.

~~~mermaid
flowchart TD
    I["Validar parâmetros"] --> R["Registrar regra e versão"]
    R --> E["Abrir execução"]
    E --> C["Localizar referências candidatas"]
    C --> A["Persistir alertas"]
    A --> V["Persistir evidências"]
    V --> F["Concluir execução"]
    C --> X["Falha: reverter parciais"]
    A --> X
    V --> X
    X --> L["Registrar SQLSTATE e mensagem"]
~~~

O alerta é único por regra, versão e transação de referência. Reexecuções com os mesmos parâmetros não duplicam o alerta. Cada evidência armazena também um snapshot JSON da transação observada.

A execução preserva regra, versão e parâmetros mesmo quando não gera alertas. A versão protege a interpretação histórica: a mesma combinação de código e versão não pode ser reutilizada com parâmetros diferentes.

O processamento de alertas e evidências ocorre em um bloco protegido. Em erro interno, esse bloco é revertido, a execução é marcada como FALHOU e recebe código e mensagem. A exceção é convertida em aviso para preservar o registro na mesma transação; por isso, integrações devem verificar o estado persistido.

## Fluxo experimental

1. O gerador cria clientes, contas e transações determinísticas a partir de uma semente.
2. A base de fundo é executada isoladamente e deve produzir zero alertas no cenário controlado atual.
3. O injetor positivo cria contas exclusivas com cinco saídas consecutivas e registra a referência esperada.
4. O injetor negativo cria casos abaixo do limiar, fora da janela, com direção mista e divididos entre contas.
5. A R01 é executada e as contagens de alertas e evidências são comparadas ao ground truth construído.
6. Benchmarks repetem o procedimento com aquecimento, validações e resumo por mediana e dispersão.

Esse ground truth comprova apenas que a implementação reconhece o padrão definido. Ele não mede recall de lavagem de dinheiro real.
## Decisões e propriedades atuais

- Toda lógica principal reside no PostgreSQL, reduzindo dependências do protótipo.
- Restrições, chaves e checks impedem vários estados inválidos.
- Alertas guardam os parâmetros utilizados e evidências associadas.
- Os testes comparativos usam transações com ROLLBACK, evitando alterações permanentes.
- A ordem das condições é alternada nos benchmarks comparativos.
- O projeto privilegia reprodutibilidade e explicitação de limitações.

## Lacunas arquiteturais conhecidas

1. O modo LEGADO_SEM_BASE continua disponível para testes manuais sobre registros sem base_id; bases normais precisam estar cadastradas.
2. Como a falha é convertida em aviso para preservar o registro, o cliente precisa consultar o estado final da execução.
3. Não há controle de acesso por papéis, segregação de funções ou trilha protegida contra alteração administrativa.
4. Não há particionamento, retenção, arquivamento ou política de descarte.
5. Não há execução incremental; a R01 varre o conjunto disponível e usa unicidade para evitar duplicação.
6. Não há concorrência controlada nem isolamento de duas execuções simultâneas da mesma regra.
7. O armazenamento de snapshots JSON aumenta o volume e ainda não tem política de minimização.
8. Monitoramento operacional, backup, restauração e observabilidade estão fora do protótipo atual.

## Relação com os arquivos

- sql/001_BASE_TCC.sql: esquema, índice e auditoria.
- sql/003_REGRA_R01.sql: processamento, alertas e evidências.
- sql/005_GERADOR_BASE_SINTETICA.sql: geração reproduzível.
- sql/008_CENARIOS_CONTROLADOS_R01.sql: cenários positivos construídos.
- sql/013_CENARIOS_NEGATIVOS_R01.sql: cenários negativos próximos ao limiar.
- sql/015_REGISTRO_FALHA_EXECUCAO.sql: migração idempotente para registro de falhas.
- sql/017_ISOLAMENTO_BASE_TRANSACAO.sql: migração idempotente para associação das transações à base.
- sql/019_RASTREABILIDADE_EXECUCAO.sql: migração para regra, versão e parâmetros na execução.
- tests/020_TESTE_VALIDACOES_EXECUCAO_R01.sql: entradas inválidas e rastreabilidade sem alertas.
- tests/: demais validações funcionais e experimentos, incluindo falha controlada e isolamento entre bases.
- resultados/: registros interpretados das execuções.
- docs/PLANO_EXPERIMENTO_R01.md: protocolo proposto e ameaças à validade.

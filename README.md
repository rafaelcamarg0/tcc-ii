# TCC II — Protótipo de auditoria e monitoramento PLD/FT

Ambiente técnico do TCC de Rafael de Camargo da Silva.

## Escopo atual

- PostgreSQL 17 executado em Docker Desktop.
- Dados exclusivamente sintéticos.
- Auditoria de INSERT, UPDATE e DELETE em transações.
- Primeira regra: R01, frequência de saídas em janela temporal.
- Alertas representam situações para análise, não comprovação de ilícito.

## Subir o ambiente

1. Iniciar o Docker Desktop.
2. Na pasta do projeto, executar: docker compose up -d.
3. Verificar: docker compose ps.
4. Testar a base: docker compose exec -T postgres psql -U tcc_app -d tcc_pld -f /tests/002_TESTE_BASE_TCC.sql.
5. Testar a R01: docker compose exec -T postgres psql -U tcc_app -d tcc_pld -f /tests/004_TESTE_R01.sql.
6. Testar o gerador: docker compose exec -T postgres psql -U tcc_app -d tcc_pld -f /tests/006_TESTE_GERADOR.sql.
7. Testar cenários controlados: docker compose exec -T postgres psql -U tcc_app -d tcc_pld -f /tests/009_TESTE_CENARIOS_CONTROLADOS_R01.sql.
8. Executar benchmark repetido: docker compose exec -T postgres psql -U tcc_app -d tcc_pld -f /tests/010_BENCHMARK_REPETIDO_CONTROLADO.sql.

A senha local está em .env, arquivo ignorado pelo Git.

## Estrutura

- sql/: esquema e mecanismos do banco.
- tests/: testes funcionais e cenários sintéticos.
- docs/: especificações e decisões metodológicas.

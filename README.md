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
9. Comparar custo da auditoria: docker compose exec -T postgres psql -U tcc_app -d tcc_pld -f /tests/011_COMPARACAO_AUDITORIA.sql.
10. Comparar impacto do índice: docker compose exec -T postgres psql -U tcc_app -d tcc_pld -f /tests/012_COMPARACAO_INDICE_R01.sql.
11. Testar cenários negativos: docker compose exec -T postgres psql -U tcc_app -d tcc_pld -f /tests/014_TESTE_CENARIOS_NEGATIVOS_R01.sql.

A senha local está em .env, arquivo ignorado pelo Git.

## Execucao no Windows

Use o atalho **Iniciar TCC PLD** na Área de Trabalho. Ele inicia o Docker Desktop quando necessário, aguarda o serviço e executa docker compose up -d.

O atalho chama scripts/iniciar_ambiente.bat, que também pode ser executado diretamente ou por acesso remoto.

## Estrutura

- sql/: esquema e mecanismos do banco.
- tests/: testes funcionais e cenários sintéticos.
- docs/: especificações, arquitetura e decisões metodológicas.

## Documentação principal

- [docs/ARQUITETURA_PROTOTIPO.md](docs/ARQUITETURA_PROTOTIPO.md): componentes, modelo de dados, fluxos e lacunas.
- [docs/R01_ESPECIFICACAO.md](docs/R01_ESPECIFICACAO.md): definição funcional da primeira regra.
- [docs/PLANO_EXPERIMENTO_R01.md](docs/PLANO_EXPERIMENTO_R01.md): protocolo de avaliação e ameaças à validade.

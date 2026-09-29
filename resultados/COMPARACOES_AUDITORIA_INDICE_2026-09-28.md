# Comparações controladas: auditoria e índice

**Data:** 28/09/2026

**Status:** experimento histórico anterior ao isolamento por base; resultados não generalizáveis. Para a versão atual, usar BENCHMARK_APOS_ISOLAMENTO_2026-09-29.md.

## Ambiente

- Notebook: Intel Core i3-1115G4, 15,74 GB de RAM.
- Sistema: Windows 11 Home 10.0.26200, Docker Desktop com WSL 2.
- Docker Engine 29.8.1 e Compose 5.5.1.
- PostgreSQL 17.11, imagem oficial.
- Commit-base dos testes: 191da45, com os scripts comparativos ainda não versionados no momento da medição.
- Dados integralmente sintéticos e execução local, sem concorrência controlada.

## Método comum

Cada comparação teve uma repetição de aquecimento descartada e cinco repetições medidas. A ordem das condições foi alternada a cada repetição para reduzir viés de ordem. Os scripts executaram em transação com ROLLBACK, preservando o estado da base.

As contagens funcionais foram verificadas automaticamente em todas as repetições. Os tempos foram medidos no servidor PostgreSQL com clock_timestamp().

## Custo da auditoria durante a carga

Script: tests/011_COMPARACAO_AUDITORIA.sql.

Foram geradas 100.000 transações por repetição. Com auditoria habilitada, o teste exigiu exatamente 100.000 registros de auditoria; sem auditoria, exigiu zero.

| Condição | Tempos medidos (ms) | Mediana (ms) | Desvio-padrão (ms) |
|---|---:|---:|---:|
| Com auditoria | 3880,490; 3898,009; 4109,708; 3981,936; 3883,667 | 3898,009 | 98,054 |
| Sem auditoria | 2289,034; 1927,869; 2036,469; 1893,453; 2098,623 | 2036,469 | 157,403 |

A sobrecarga mediana calculada foi **91,41%** na carga sintética avaliada.
## Impacto do índice na R01

Script: tests/012_COMPARACAO_INDICE_R01.sql.

A comparação válida usou 10.000 transações de fundo e 100 cenários positivos controlados, totalizando 10.500 transações. Em cada condição, o teste exigiu exatamente 100 alertas e 500 evidências.

| Condição | Tempos medidos (ms) | Mediana (ms) | Desvio-padrão (ms) |
|---|---:|---:|---:|
| Com índice | 17,345; 19,218; 20,590; 21,980; 20,763 | 20,590 | 1,768 |
| Sem índice | 202,788; 223,640; 317,930; 211,185; 250,747 | 223,640 | 46,539 |

O ganho mediano calculado para o índice (conta_id, instante_evento) foi **90,79%** no tempo da R01 nesse conjunto.

## Execução exploratória interrompida

Uma tentativa inicial da condição sem índice com 105.000 transações foi interrompida após ultrapassar dois minutos, sem produzir medição válida. A transação foi revertida e o índice foi confirmado novamente no banco. Esse episódio indica custo elevado nesse ambiente, mas não constitui resultado quantitativo e não integra as tabelas acima.

## Interpretação

Os resultados sustentam duas afirmações restritas ao protótipo:

1. A auditoria por linha tem custo relevante durante a carga sintética avaliada.
2. O índice composto é decisivo para a execução da R01 no volume comparado.

Não se deve inferir desempenho em produção, escalabilidade universal ou efetividade real de PLD/FT. O teste não representa carga concorrente, hardware de servidor, distribuição bancária real nem regras múltiplas em paralelo.

## Reprodutibilidade

Executar, na raiz do projeto:

~~~powershell
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U tcc_app -d tcc_pld -f /tests/011_COMPARACAO_AUDITORIA.sql
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U tcc_app -d tcc_pld -f /tests/012_COMPARACAO_INDICE_R01.sql
~~~

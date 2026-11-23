**Benchmark controlado repetido — 28/09/2026**

> Resultado histórico anterior ao isolamento por base. Para a versão atual do protótipo, usar BENCHMARK_APOS_ISOLAMENTO_2026-09-29.md.

**Procedimento**

Para cada volume foi executada uma repetição de aquecimento, descartada, seguida de cinco medições. A semente utilizada foi 20260928. Cada repetição começou com tabelas vazias e terminou dentro de uma transação revertida.

A base de fundo recebeu dez transações por cliente. Foram acrescentados cenários positivos equivalentes a 1% do volume-base, cada um com cinco saídas consecutivas e uma referência positiva esperada.

**Resultados agregados**

| Volume-base | Total após injeção | Alertas/evidências | Mediana geração | DP geração | Mediana injeção | DP injeção | Mediana R01 | DP R01 |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1.000 | 1.050 | 10 / 50 | 29,573 ms | 3,058 | 4,169 ms | 0,753 | 21,494 ms | 2,089 |
| 10.000 | 10.500 | 100 / 500 | 335,477 ms | 16,053 | 32,826 ms | 3,505 | 19,846 ms | 2,474 |
| 100.000 | 105.000 | 1.000 / 5.000 | 4.050,594 ms | 86,505 | 367,147 ms | 13,922 | 204,082 ms | 9,816 |

DP = desvio-padrão amostral das cinco medições.

**Correção observada**

Em todas as 15 medições, a quantidade de alertas foi igual à quantidade de cenários positivos construídos, e cada alerta preservou cinco evidências. Não foram observados alertas na base de fundo com essa semente e configuração.
**Interpretação permitida**

O ensaio mostra que a implementação reproduziu os resultados esperados nos cenários controlados e processou 105 mil transações, mil alertas e cinco mil evidências em mediana de aproximadamente 204 ms para a R01 neste ambiente.

A cobertura funcional dos cenários construídos foi de 100%. Esse valor não representa recall real de PLD/FT, pois os casos foram construídos a partir da própria definição da regra.

**Limitações**

- O conjunto positivo foi construído para satisfazer exatamente a R01.
- Não há casos reais, anonimizados ou avaliados por especialista.
- A ausência de alertas na base de fundo depende desta semente e distribuição.
- A ordem dos volumes não foi aleatorizada.
- Foram realizadas somente cinco repetições medidas.
- Não houve comparação com a R01 sem índice ou com outra estratégia.
- O ambiente concorreu com processos normais do notebook.
- O tempo medido reúne leitura, decisão e persistência de alertas/evidências.

**Uso recomendado**

Estes números são do ensaio de desenvolvimento.

# Benchmark após isolamento por base — 29/09/2026

## Escopo

Medições refeitas após o isolamento por base e repetidas depois do reforço das validações e da rastreabilidade das execuções. Houve uma execução de aquecimento descartada e cinco repetições medidas por condição.

## Volume controlado

| Volume-base | Transações totais | Alertas / evidências | Mediana geração | DP geração | Mediana injeção | DP injeção | Mediana R01 | DP R01 |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1.000 | 1.050 | 10 / 50 | 54,940 ms | 4,762 | 5,554 ms | 1,743 | 5,454 ms | 0,905 |
| 10.000 | 10.500 | 100 / 500 | 466,143 ms | 140,700 | 37,428 ms | 56,404 | 34,235 ms | 6,609 |
| 100.000 | 105.000 | 1.000 / 5.000 | 5.838,955 ms | 376,855 | 458,398 ms | 74,090 | 311,735 ms | 120,663 |

Todas as repetições produziram as quantidades esperadas de alertas e evidências.

## Comparação do índice

Carga: 10.000 transações de fundo e 100 cenários positivos, totalizando 10.500 transações.

| Condição | Medições (ms) | Mediana | DP |
|---|---|---:|---:|
| Com índice | 39,343; 51,532; 28,196; 26,762; 28,087 | 28,196 ms | 10,652 |
| Sem índice | 8.473,675; 7.544,593; 7.859,094; 6.900,527; 7.507,025 | 7.544,593 ms | 573,406 |

Ganho mediano calculado para o índice: **99,63%**. As duas condições mantiveram 100 alertas e 500 evidências.

## Comparação da auditoria

Carga: 100.000 transações sintéticas.

| Condição | Medições (ms) | Mediana | DP |
|---|---|---:|---:|
| Com auditoria | 4.897,844; 5.469,855; 5.175,409; 5.022,198; 5.010,361 | 5.022,198 ms | 221,523 |
| Sem auditoria | 2.860,787; 3.040,682; 2.638,889; 2.862,110; 2.646,445 | 2.860,787 ms | 169,217 |

Sobrecarga mediana calculada para a auditoria: **75,55%**. A condição habilitada registrou 100.000 eventos em todas as repetições; a desabilitada registrou zero.

## Interpretação

Os números substituem, para a versão atual do protótipo, as medições de 28/09/2026. O filtro por base alterou o plano e o custo da R01, sobretudo sem o índice composto. Por isso, não se deve combinar medianas das duas versões em uma mesma comparação.

Os resultados mostram comportamento técnico no notebook de desenvolvimento e não representam desempenho universal. O ganho do índice e a sobrecarga da auditoria dependem da distribuição sintética, do volume, do cache, do hardware e da consulta implementada.

## Verificações adicionais

Após a mudança, passaram:

- os 12 casos funcionais originais da R01;
- reprodutibilidade do gerador;
- cenários positivos e negativos;
- registro de falha controlada;
- isolamento entre duas bases sintéticas;
- rejeição de parâmetros nulos e identificadores de base inexistentes;
- rastreabilidade completa de execuções sem alertas;
- benchmark repetido, comparação de índice e comparação de auditoria.

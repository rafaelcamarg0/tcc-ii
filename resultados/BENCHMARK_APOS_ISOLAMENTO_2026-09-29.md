# Benchmark após isolamento por base — 29/09/2026

## Escopo

Medições refeitas após a associação de cada transação a uma base sintética e o filtro da R01 pelo identificador da base. Houve uma execução de aquecimento descartada e cinco repetições medidas por condição.

## Volume controlado

| Volume-base | Transações totais | Alertas / evidências | Mediana geração | DP geração | Mediana injeção | DP injeção | Mediana R01 | DP R01 |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1.000 | 1.050 | 10 / 50 | 42,686 ms | 3,268 | 5,537 ms | 0,675 | 4,792 ms | 1,122 |
| 10.000 | 10.500 | 100 / 500 | 451,111 ms | 16,597 | 41,319 ms | 7,897 | 26,103 ms | 5,176 |
| 100.000 | 105.000 | 1.000 / 5.000 | 5.412,765 ms | 628,661 | 413,176 ms | 55,192 | 319,078 ms | 85,019 |

Todas as repetições produziram as quantidades esperadas de alertas e evidências.
## Comparação do índice

Carga: 10.000 transações de fundo e 100 cenários positivos, totalizando 10.500 transações.

| Condição | Medições (ms) | Mediana | DP |
|---|---|---:|---:|
| Com índice | 26,625; 28,153; 23,795; 28,090; 54,189 | 28,090 ms | 12,435 |
| Sem índice | 8.008,788; 7.759,428; 7.904,048; 7.918,490; 7.464,768 | 7.904,048 ms | 213,230 |

Ganho mediano calculado para o índice: **99,64%**. As duas condições mantiveram 100 alertas e 500 evidências.

## Comparação da auditoria

Carga: 100.000 transações sintéticas.

| Condição | Medições (ms) | Mediana | DP |
|---|---|---:|---:|
| Com auditoria | 6.387,345; 6.652,833; 7.009,060; 5.258,419; 4.885,727 | 6.387,345 ms | 919,034 |
| Sem auditoria | 3.352,245; 3.575,951; 3.817,741; 2.838,660; 2.438,326 | 3.352,245 ms | 560,520 |

Sobrecarga mediana calculada para a auditoria: **90,54%**. A condição habilitada registrou 100.000 eventos em todas as repetições; a desabilitada registrou zero.
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
- benchmark repetido, comparação de índice e comparação de auditoria.

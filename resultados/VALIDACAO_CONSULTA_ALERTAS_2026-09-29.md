# Validação da consulta de alertas — 29/09/2026

## Objetivo

Demonstrar que os dados persistidos pelo protótipo podem ser reconstruídos em uma consulta legível para revisão humana, sem navegar manualmente por regra, execução, alerta, transação e evidências.

## Implementação

A view tcc_pld.vw_alerta_explicado, definida em sql/021_CONSULTA_ALERTAS.sql, apresenta:

- regra e versão;
- execução, base e estado;
- cliente e conta sintéticos;
- transação de referência;
- quantidade observada e parâmetros;
- quantidade de evidências;
- snapshots JSON das transações que sustentaram o alerta.

## Resultado

O teste tests/022_TESTE_CONSULTA_ALERTAS.sql criou uma base sintética, injetou um cenário positivo, executou a R01 e recuperou um alerta concluído com quantidade observada igual a cinco e cinco evidências. O teste passou no banco atual e em uma instalação limpa.

## Interpretação

A consulta demonstra apoio à reconstrução e à revisão do alerta. Ela não constitui uma interface gráfica, não decide sobre suspeição e não substitui a análise humana.

# Validação de cenários negativos da R01

**Data:** 28/09/2026

**Script:** tests/014_TESTE_CENARIOS_NEGATIVOS_R01.sql

## Objetivo

Verificar se a R01 evita alertas em casos próximos ao limiar e se esses casos permanecem negativos quando avaliados junto com cenários positivos construídos.

## Casos injetados

Foram criadas cinco instâncias de cada tipo, sempre em clientes e contas sintéticos exclusivos.

| Tipo | Construção | Alertas esperados |
|---|---|---:|
| Abaixo do limiar | Quatro saídas em minutos consecutivos | 0 |
| Fora da janela | Cinco saídas separadas por três minutos | 0 |
| Direção mista | Quatro saídas e uma entrada em cinco minutos | 0 |
| Contas separadas | Três saídas em uma conta e duas em outra do mesmo cliente | 0 |

A base de fundo continha 1.000 transações. Os 20 cenários negativos acrescentaram 95 movimentos, totalizando 1.095 transações antes da mistura com positivos.
## Resultados

Na execução isolada, os 20 cenários negativos produziram zero alertas.

Em seguida, foram acrescentados dez cenários positivos, cada um com cinco saídas consecutivas. A execução conjunta produziu:

- 10 alertas;
- 50 evidências;
- nenhum alerta cuja referência estivesse fora do conjunto positivo construído.

Todas as verificações foram automáticas e a execução ocorreu em transação revertida.

## Interpretação

O resultado amplia a validação funcional para casos próximos ao limiar e confirma a separação por direção, janela, conta e quantidade mínima no conjunto construído.

Não se deve interpretar o resultado como estimativa de especificidade ou taxa de falsos positivos em dados bancários reais. Os negativos também foram definidos a partir da lógica conhecida da R01 e não constituem amostra independente do fenômeno de PLD/FT.

## Reprodução

~~~powershell
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U tcc_app -d tcc_pld -f /tests/014_TESTE_CENARIOS_NEGATIVOS_R01.sql
~~~

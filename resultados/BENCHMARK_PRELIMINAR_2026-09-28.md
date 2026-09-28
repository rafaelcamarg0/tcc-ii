# Benchmark preliminar — 28/09/2026

## Objetivo

Verificar se o gerador e a R01 executam em volumes crescentes antes de definir o experimento final. Os dados foram gerados com a semente 20260928 e revertidos após cada volume.

| Transações | Clientes | Geração com auditoria | Execução da R01 | Alertas |
|---:|---:|---:|---:|---:|
| 1.000 | 100 | 36,553 ms | 16,314 ms | 0 |
| 10.000 | 1.000 | 366,407 ms | 7,318 ms | 0 |
| 100.000 | 10.000 | 3.885,389 ms | 90,665 ms | 0 |

Em todos os volumes, a quantidade de registros de auditoria foi igual à quantidade de transações inseridas.

## Leitura preliminar

A geração apresentou crescimento aproximadamente proporcional ao volume. A R01 processou 100 mil transações em menos de 100 ms neste ambiente e nesta distribuição.

O resultado de 10 mil transações menor que o de 1 mil indica influência de compilação, aquecimento e cache. Portanto, esses tempos não devem ser apresentados como comparação final de desempenho.

## Limitações

- Foi realizada apenas uma execução por volume.
- Não houve controle de cache nem aquecimento separado.
- A distribuição aleatória não gerou alertas.
- Não foi medido o custo de persistir alertas e evidências em volume.
- Não houve comparação com mecanismo alternativo ou versão sem auditoria.
- Os números descrevem somente este ambiente e esta implementação.

## Consequência metodológica

O experimento final deve usar aquecimento, várias repetições, mediana e dispersão; manter razão clientes/transações documentada; incluir cenários com disparos controlados; e separar tempo de carga, custo da auditoria e tempo da R01.

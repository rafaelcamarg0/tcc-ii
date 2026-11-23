# Verificação funcional de 21/11/2026

Windows no notebook de Rafael. Docker Engine 29.8.1, Docker Compose 5.5.1 e PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2). O checkout de desenvolvimento indicou 6a46707. A revisão v2 do mapa e o ZIP extraído no Windows tinham o mesmo SHA-256. O teste usou diretório, nome de projeto e volume próprios, sem publicar porta.

| Evidência | Execução |
|---|---|
| demo-original.log e validacao.log | Revisão v2 antes das alterações. Ambas saíram com código 0. |
| demo-final.log | Primeira demonstração da cópia ajustada, iniciada em outro projeto Compose com volume novo. Código 0. |
| validacao-final.log | Nove arquivos de testes passaram. Inclui C01–C12 e falhas ao gravar o alerta e a terceira evidência. Código 0. |
| demo-repetida.log | Segunda demonstração da cópia ajustada, depois da suíte. Código 0. |
| 01-fundo-auditoria.png e 02-alerta-evidencias.png | Capturas no Windows da visualização de trechos do log do psql. Os dados das tabelas vêm da saída de demo-final.log. |
| SHA256_ARQUIVOS_EXECUTADOS.txt | Hash dos 29 arquivos de SQL, testes, scripts e Compose lidos no notebook e comparados com o ZIP de entrega. |

Consulta de conferência depois do ROLLBACK da demonstração repetida, na ordem transações, alertas, evidências e auditoria: 0|0|0|0. Durante a demonstração houve 100 movimentações sem alerta, depois 105 movimentações, um alerta vinculado à execução 2, cinco evidências e 105 inclusões auditadas. As linhas mostram dados fictícios de janeiro, e os arquivos registram o ensaio de novembro.

Os resultados de tempo pertencem à rodada de 29/09/2026. Esta verificação não mediu desempenho nem envolveu usuários externos.

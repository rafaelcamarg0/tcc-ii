# TCC II

Prototipo de auditoria e monitoramento de transações em PostgreSQL.
Rafael de Camargo da Silva, Ciência da Computação, IFFar Frederico Westphalen.

A R01 conta saídas de uma conta em uma janela de tempo. O alerta guarda as movimentações contadas, com os códigos e os horários.


## Rodar no Windows

Baixe o ZIP pelo botão Code ou clone o repositório. Abra o Docker Desktop com contêineres Linux e rode [demonstrar_prototipo.bat](scripts/demonstrar_prototipo.bat). O primeiro uso pode precisar baixar a imagem postgres:17.

A primeira execução mostra 100 movimentações e zero alertas. Depois de acrescentar cinco saídas da mesma conta, aparece um alerta com cinco evidências. A auditoria mostra 105 inclusões. No fim, o ROLLBACK desfaz os dados temporários da demo.

## Validacao

Rode [validar_projeto.bat](scripts/validar_projeto.bat). O caso C01 tem quatro saídas e deve terminar sem alerta. O teste 016 força falhas de gravação e confere se o banco desfez os registros parciais.

Se já tiver outra cópia rodando, use um nome de projeto diferente no PowerShell, na pasta do repositório:

~~~powershell
$env:COMPOSE_PROJECT_NAME = "tcc_pld_banca_rafael"
.\scripts\demonstrar_prototipo.bat
.\scripts\validar_projeto.bat
docker compose stop
~~~

## Registros

[Logs e capturas da validação](resultados/2026-11-21)  
[Medições de desempenho usadas no artigo](resultados/BENCHMARK_APOS_ISOLAMENTO_2026-09-29.md)

@echo off
setlocal EnableExtensions
cd /d "%~dp0.."

where docker >nul 2>&1 || goto sem_docker
if not exist ".env" (
    copy /Y ".env.example" ".env" >nul
    echo Arquivo .env criado a partir do exemplo para uso local.
)

docker info >nul 2>&1 || goto docker_parado
docker compose up -d || goto falha
echo Aguardando o PostgreSQL ficar pronto...
for /L %%I in (1,1,60) do (
    docker compose exec -T postgres pg_isready -U tcc_app -d tcc_pld >nul 2>&1 && goto testar
    timeout /t 2 /nobreak >nul
)
goto falha

:testar
echo Atualizando objetos idempotentes do banco...
for %%F in (
    005_GERADOR_BASE_SINTETICA.sql
    015_REGISTRO_FALHA_EXECUCAO.sql
    017_ISOLAMENTO_BASE_TRANSACAO.sql
    019_RASTREABILIDADE_EXECUCAO.sql
    003_REGRA_R01.sql
    008_CENARIOS_CONTROLADOS_R01.sql
    013_CENARIOS_NEGATIVOS_R01.sql
    021_CONSULTA_ALERTAS.sql
) do (
    docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U tcc_app -d tcc_pld -f /sql/%%F
    if errorlevel 1 goto falha
)

for %%F in (
    002_TESTE_BASE_TCC.sql
    004_TESTE_R01.sql
    006_TESTE_GERADOR.sql
    009_TESTE_CENARIOS_CONTROLADOS_R01.sql
    014_TESTE_CENARIOS_NEGATIVOS_R01.sql
    016_TESTE_REGISTRO_FALHA_R01.sql
    018_TESTE_ISOLAMENTO_BASE_R01.sql
    020_TESTE_VALIDACOES_EXECUCAO_R01.sql
    022_TESTE_CONSULTA_ALERTAS.sql
) do (
    echo.
    echo Executando %%F...
    docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U tcc_app -d tcc_pld -f /tests/%%F
    if errorlevel 1 goto falha
)

echo.
echo VALIDACAO COMPLETA: TODOS OS TESTES PASSARAM.
pause
exit /b 0

:sem_docker
echo Docker nao foi encontrado. Instale e abra o Docker Desktop.
pause
exit /b 1

:docker_parado
echo Docker Desktop esta instalado, mas nao esta pronto.
pause
exit /b 1

:falha
echo.
echo A validacao foi interrompida porque uma etapa falhou.
pause
exit /b 1

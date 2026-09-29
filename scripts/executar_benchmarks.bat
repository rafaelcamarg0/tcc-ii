@echo off
setlocal EnableExtensions
cd /d "%~dp0.."

where docker >nul 2>&1 || goto sem_docker
if not exist ".env" (
    copy /Y ".env.example" ".env" >nul
)
docker info >nul 2>&1 || goto docker_parado
docker compose up -d || goto falha

echo.
echo Os benchmarks podem levar alguns minutos.
echo Feche programas pesados para reduzir interferencias.
for %%F in (
    010_BENCHMARK_REPETIDO_CONTROLADO.sql
    011_COMPARACAO_AUDITORIA.sql
    012_COMPARACAO_INDICE_R01.sql
) do (
    echo.
    echo Executando %%F...
    docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U tcc_app -d tcc_pld -f /tests/%%F
    if errorlevel 1 goto falha
)

echo.
echo BENCHMARKS CONCLUIDOS.
pause
exit /b 0

:sem_docker
echo Docker nao foi encontrado.
pause
exit /b 1

:docker_parado
echo Abra o Docker Desktop e execute novamente.
pause
exit /b 1

:falha
echo Um benchmark falhou ou foi interrompido.
pause
exit /b 1

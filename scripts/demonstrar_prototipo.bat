@echo off
setlocal EnableExtensions
cd /d "%~dp0.."

where docker >nul 2>&1 || goto sem_docker
if not exist ".env" copy /Y ".env.example" ".env" >nul

docker info >nul 2>&1 && goto iniciar
if exist "C:\Program Files\Docker\Docker\Docker Desktop.exe" (
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    echo Aguardando o Docker Desktop...
    for /L %%I in (1,1,90) do (
        docker info >nul 2>&1 && goto iniciar
        timeout /t 2 /nobreak >nul
    )
)
goto docker_parado

:iniciar
docker compose up -d || goto falha
echo Aguardando o PostgreSQL...
for /L %%I in (1,1,60) do (
    docker compose exec -T postgres pg_isready -U tcc_app -d tcc_pld >nul 2>&1 && goto demonstrar
    timeout /t 2 /nobreak >nul
)
goto falha

:demonstrar
cls
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U tcc_app -d tcc_pld -f /tests/023_DEMONSTRACAO_ORIENTACAO.sql
if errorlevel 1 goto falha

echo.
echo A demonstracao terminou sem alterar permanentemente o banco.
pause
exit /b 0

:sem_docker
echo Docker nao encontrado. Instale o Docker Desktop.
pause
exit /b 1

:docker_parado
echo Nao foi possivel iniciar o Docker Desktop.
pause
exit /b 1

:falha
echo.
echo A demonstracao foi interrompida por uma falha.
pause
exit /b 1

@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0.." || exit /b 1

where docker >nul 2>&1
if errorlevel 1 (
    echo Docker nao encontrado. Instale e abra o Docker Desktop.
    exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
    echo Abra o Docker Desktop, espere iniciar e tente de novo.
    exit /b 1
)

if not exist ".env" (
    powershell.exe -NoProfile -Command "[IO.File]::WriteAllLines('.env',[string[]]@('POSTGRES_DB=tcc_pld','POSTGRES_USER=tcc_app',('POSTGRES_PASSWORD='+[guid]::NewGuid().ToString('N'))))"
    if errorlevel 1 (
        echo Nao consegui criar o .env. Veja o README para configurar manualmente.
        exit /b 1
    )
)

echo Aguardando o PostgreSQL da copia de revisao...
docker compose up -d --wait --wait-timeout 180
if errorlevel 1 (
    docker compose logs --tail 30 postgres
    exit /b 1
)
exit /b 0

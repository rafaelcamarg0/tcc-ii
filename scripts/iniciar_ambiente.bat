@echo off
setlocal
cd /d "%~dp0.."
set "DOCKER=C:\Program Files\Docker\Docker\resources\bin\docker.exe"
set "DOCKER_DESKTOP=C:\Program Files\Docker\Docker\Docker Desktop.exe"

if not exist "%DOCKER%" goto sem_docker
"%DOCKER%" info >nul 2>&1 && goto docker_pronto
if not exist "%DOCKER_DESKTOP%" goto sem_docker
start "" "%DOCKER_DESKTOP%"
echo Aguardando o Docker Desktop ficar pronto...

for /L %%I in (1,1,90) do (
    "%DOCKER%" info >nul 2>&1 && goto docker_pronto
    timeout /t 2 /nobreak >nul
)

echo Tempo limite excedido ao aguardar o Docker Desktop.
pause
exit /b 1

:docker_pronto
"%DOCKER%" compose up -d
if errorlevel 1 goto erro_compose
"%DOCKER%" compose ps
echo.
echo Ambiente do TCC iniciado.
echo PostgreSQL local: 127.0.0.1:5432
pause
exit /b 0

:sem_docker
echo Docker Desktop nao encontrado.
pause
exit /b 1

:erro_compose
echo Nao foi possivel iniciar o ambiente.
pause
exit /b 1

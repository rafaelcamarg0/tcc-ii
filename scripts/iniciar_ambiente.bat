@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0.." || exit /b 1
call "%~dp0preparar_ambiente.bat"
if errorlevel 1 goto falha
docker compose ps
if errorlevel 1 goto falha
echo Banco da revisao pronto.
pause
exit /b 0

:falha
echo Nao foi possivel iniciar o banco da revisao.
pause
exit /b 1

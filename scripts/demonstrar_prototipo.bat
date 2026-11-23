@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0.." || exit /b 1
call "%~dp0preparar_ambiente.bat"
if errorlevel 1 goto falha
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U tcc_app -d tcc_pld -f /tests/023_DEMONSTRACAO_ORIENTACAO.sql
if errorlevel 1 goto falha
echo.
echo Demonstracao concluida. Confira o alerta e as evidencias acima.
pause
exit /b 0

:falha
echo A demonstracao foi interrompida.
pause
exit /b 1

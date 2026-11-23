@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0.." || exit /b 1
call "%~dp0preparar_ambiente.bat"
if errorlevel 1 goto falha

echo Os benchmarks podem levar alguns minutos.
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
echo BENCHMARKS CONCLUIDOS.
pause
exit /b 0

:falha
echo Um benchmark falhou ou foi interrompido.
pause
exit /b 1

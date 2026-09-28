$ErrorActionPreference = "Stop"
Write-Host "Instalando o WSL para o ambiente do TCC..." -ForegroundColor Cyan
winget install --id Microsoft.WSL -e --accept-package-agreements --accept-source-agreements --silent
wsl.exe --install --no-distribution
Write-Host ""
Write-Host "Etapa concluida. O Windows pode precisar ser reiniciado." -ForegroundColor Green
Read-Host "Pressione Enter para fechar"

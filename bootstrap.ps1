$ErrorActionPreference = "Stop"

Write-Host "TurnoPronto Android - bootstrap Flutter" -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter não encontrado no PATH." -ForegroundColor Red
    Write-Host "Instale o Flutter stable e rode este script novamente."
    exit 1
}

flutter --version

if (-not (Test-Path "android")) {
    Write-Host "Gerando shell nativo Android..." -ForegroundColor Yellow
    flutter create --platforms=android --project-name turnopronto_app --org br.com.turnopronto .
}

flutter pub get
flutter analyze

Write-Host ""
Write-Host "Projeto pronto." -ForegroundColor Green
Write-Host "Execute: flutter run"
Write-Host "API fixa: https://turnopronto.com.br/api/v1"

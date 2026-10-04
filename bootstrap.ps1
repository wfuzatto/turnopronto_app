$ErrorActionPreference = "Stop"

Write-Host "TurnoPronto App - bootstrap Flutter" -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter não encontrado no PATH." -ForegroundColor Red
    Write-Host "Instale o Flutter stable e rode este script novamente."
    exit 1
}

flutter --version

if (-not (Test-Path "android") -or -not (Test-Path "ios")) {
    Write-Host "Gerando shells nativos Android/iOS..." -ForegroundColor Yellow
    flutter create --platforms=android,ios --project-name turnopronto_app .
}

flutter pub get
flutter analyze

Write-Host "\nProjeto pronto." -ForegroundColor Green
Write-Host "Execute: flutter run"\nWrite-Host "API fixa: https://turnopronto.com.br/api/v1"

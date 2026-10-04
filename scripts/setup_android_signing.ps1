param(
    [string]$Repository = "wfuzatto/turnopronto_app"
)

$ErrorActionPreference = "Stop"

function Get-KeytoolPath {
    $cmd = Get-Command keytool -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $candidates = @()
    if ($env:JAVA_HOME) {
        $candidates += (Join-Path $env:JAVA_HOME "bin\keytool.exe")
    }
    if ($env:ProgramFiles) {
        $candidates += (Join-Path $env:ProgramFiles "Android\Android Studio\jbr\bin\keytool.exe")
        $candidates += (Join-Path $env:ProgramFiles "Android\Android Studio\jre\bin\keytool.exe")
    }

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) { return $candidate }
    }

    throw "keytool não encontrado. Instale o Android Studio/JDK ou configure JAVA_HOME."
}

function New-RandomSecret([int]$Length = 36) {
    $alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%_-"
    $bytes = New-Object byte[] $Length
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    } finally {
        $rng.Dispose()
    }

    $chars = for ($i = 0; $i -lt $Length; $i++) {
        $alphabet[$bytes[$i] % $alphabet.Length]
    }
    return -join $chars
}

$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
    throw "GitHub CLI (gh) não encontrado. Instale-o e execute 'gh auth login' antes deste script."
}

& gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI não está autenticado. Execute 'gh auth login' e rode este script novamente."
}

$keytool = Get-KeytoolPath
$backupDir = Join-Path $HOME "TurnoPronto-Signing-Backup"
$keystorePath = Join-Path $backupDir "turnopronto-upload.jks"
$recoveryPath = Join-Path $backupDir "signing-recovery.txt"
$alias = "turnopronto"

New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

if ((Test-Path $keystorePath) -xor (Test-Path $recoveryPath)) {
    throw "Backup incompleto encontrado em $backupDir. Não vou sobrescrever. Corrija/remova o backup incompleto manualmente."
}

if ((Test-Path $keystorePath) -and (Test-Path $recoveryPath)) {
    Write-Host "Backup de assinatura existente encontrado. Reutilizando a chave definitiva." -ForegroundColor Yellow
    $recovery = Get-Content $recoveryPath
    $passwordLine = $recovery | Where-Object { $_ -like "PASSWORD=*" } | Select-Object -First 1
    $aliasLine = $recovery | Where-Object { $_ -like "ALIAS=*" } | Select-Object -First 1

    if (-not $passwordLine -or -not $aliasLine) {
        throw "Arquivo de recuperação inválido: $recoveryPath"
    }

    $password = $passwordLine.Substring("PASSWORD=".Length)
    $alias = $aliasLine.Substring("ALIAS=".Length)
} else {
    $password = New-RandomSecret 40

    Write-Host "Gerando chave Android definitiva..." -ForegroundColor Cyan
    $keytoolArgs = @(
        "-genkeypair",
        "-v",
        "-keystore", $keystorePath,
        "-storepass", $password,
        "-keypass", $password,
        "-alias", $alias,
        "-keyalg", "RSA",
        "-keysize", "4096",
        "-validity", "10000",
        "-dname", "CN=TurnoPronto, OU=Mobile, O=TurnoPronto, L=Passa Quatro, ST=Minas Gerais, C=BR"
    )
    & $keytool @keytoolArgs

    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $keystorePath)) {
        throw "Falha ao gerar a chave Android."
    }

    @(
        "TURNOPRONTO ANDROID SIGNING - BACKUP CONFIDENCIAL",
        "Não versionar nem enviar este arquivo para o GitHub.",
        "",
        "ALIAS=$alias",
        "PASSWORD=$password",
        "KEYSTORE=$keystorePath",
        "CREATED_AT=$([DateTime]::Now.ToString('s'))"
    ) | Set-Content -Path $recoveryPath -Encoding UTF8
}

Write-Host "Validando chave..." -ForegroundColor Cyan
& $keytool -list -keystore $keystorePath -storepass $password -alias $alias | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "A chave existente não pôde ser validada com a senha do arquivo de recuperação."
}

$base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($keystorePath))

Write-Host "Cadastrando secrets no GitHub..." -ForegroundColor Cyan
$base64 | & gh secret set ANDROID_KEYSTORE_BASE64 --repo $Repository
if ($LASTEXITCODE -ne 0) { throw "Falha ao gravar ANDROID_KEYSTORE_BASE64." }

$password | & gh secret set ANDROID_KEYSTORE_PASSWORD --repo $Repository
if ($LASTEXITCODE -ne 0) { throw "Falha ao gravar ANDROID_KEYSTORE_PASSWORD." }

$alias | & gh secret set ANDROID_KEY_ALIAS --repo $Repository
if ($LASTEXITCODE -ne 0) { throw "Falha ao gravar ANDROID_KEY_ALIAS." }

$password | & gh secret set ANDROID_KEY_PASSWORD --repo $Repository
if ($LASTEXITCODE -ne 0) { throw "Falha ao gravar ANDROID_KEY_PASSWORD." }

Write-Host "Secrets cadastrados." -ForegroundColor Green
Write-Host "Backup local: $backupDir" -ForegroundColor Yellow
Write-Host "Guarde essa pasta em local seguro. Sem esta chave, futuras atualizações APK não poderão substituir a versão instalada." -ForegroundColor Yellow

Write-Host "Disparando novo build Android..." -ForegroundColor Cyan
& gh workflow run "android-apk.yml" --repo $Repository
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Os secrets foram cadastrados, mas não consegui disparar o workflow automaticamente."
    Write-Host "Execute: gh workflow run android-apk.yml --repo $Repository"
    exit 0
}

Write-Host "Concluído. O novo workflow foi disparado." -ForegroundColor Green

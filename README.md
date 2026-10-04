# TurnoPronto Android

Aplicativo Android oficial do TurnoPronto para profissionais.

Este repositório é exclusivo do cliente Android. O backend/API permanece em `wfuzatto/turnopronto_web` e o cliente iOS em `wfuzatto/turnopronto_ios`.

## Comunicação

O aplicativo se comunica automaticamente por HTTPS com:

```text
https://turnopronto.com.br/api/v1
```

O banco MariaDB é acessado somente pelo backend web. Nenhuma credencial de banco deve ser incluída no APK.

## Desenvolvimento

```powershell
./bootstrap.ps1
flutter run
```

## Build Android e atualização

O GitHub Actions gera um APK Android com o mesmo identificador:

```text
br.com.turnopronto.turnopronto_app
```

Para que uma versão nova atualize a já instalada sem conflito, todos os APKs precisam ser assinados pela mesma chave e possuir `versionCode` maior.

O workflow espera os seguintes GitHub Actions Secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Depois que essa chave de assinatura for definida, ela deve ser preservada para todas as versões futuras.

Download permanente da versão de teste:

```text
https://github.com/wfuzatto/turnopronto_app/releases/download/test-latest/TurnoPronto.apk
```

## Funcionalidades

- login e autocadastro;
- validação de cadastro via WhatsApp;
- oportunidades;
- detalhe e aceite de vaga;
- turnos e agenda;
- check-in/check-out;
- ganhos;
- perfil, documentos e reputação.

Nenhuma senha de banco, token de provedor, chave de assinatura ou outro segredo deve ser versionado neste repositório.

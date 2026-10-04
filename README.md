# TurnoPronto Android

Aplicativo Android oficial do TurnoPronto para profissionais.

Este repositório é exclusivo do cliente Android. O backend/API permanece em `wfuzatto/turnopronto_web` e o cliente iOS em `wfuzatto/turnopronto_ios`.

## Comunicação

A comunicação do aplicativo é fixa via HTTPS:

```text
https://turnopronto.com.br/api/v1
```

O aplicativo nunca acessa o banco MariaDB diretamente e não oferece configuração de servidor ao usuário.

## Desenvolvimento

```powershell
./bootstrap.ps1
flutter run
```

## Build de teste

O GitHub Actions gera automaticamente o APK a partir do branch `main`.

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

Nenhuma senha de banco, token de provedor ou outro segredo deve ser versionado neste repositório.

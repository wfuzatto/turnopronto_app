# TurnoPronto App

Aplicativo Flutter para profissionais da TurnoPronto, com alvo Android e iOS.

> **Marca:** TurnoPronto  
> **Slogan:** “Nós cuidamos do extra que você precisa.”

## Stack

- Flutter 3.47.x (stable em outubro/2026)
- Dart 3.x
- Material 3
- sem Docker
- sem gerenciador de estado externo no MVP
- sem dependências de rede além do próprio `dart:io` no núcleo atual
- backend: `turnopronto_web` / PHP REST API

## Telas já implementadas

- Login
- modo demonstração sem servidor
- Início / feed de vagas
- cards de confiabilidade e ganhos
- detalhe da vaga
- aceite
- Meus turnos
- Turno atual
- check-in por PIN
- check-out
- confirmação de localização (visual no MVP)
- QR visual de referência
- Agenda
- Ganhos
- Perfil / reputação
- navegação inferior completa

O design segue o mockup aprovado: branco, azul/verde TurnoPronto, cards arredondados, informação operacional em primeiro plano e ações claras.

## Primeiro bootstrap

Este repositório contém todo o código Flutter da aplicação. Como o ambiente que gerou o projeto não possui o SDK Flutter instalado, os shells nativos padrão (`android/` e `ios/`) devem ser criados uma vez com o próprio Flutter SDK.

### Windows / PowerShell

```powershell
./bootstrap.ps1
```

Ou manualmente:

```powershell
flutter create --platforms=android,ios --project-name turnopronto_app .
flutter pub get
```

Depois, o conteúdo em `lib/` permanece sendo a implementação TurnoPronto.

## Rodar sem backend

```bash
flutter run
```

Na tela de login use **Abrir demonstração sem servidor**.

## Rodar conectado ao XAMPP

O celular/emulador precisa alcançar o computador que está executando `turnopronto_web`.

### Android Emulator

```bash
flutter run --dart-define=API_URL=http://10.0.2.2/turnopronto_web/api/v1
```

### Celular físico Android/iPhone na mesma rede

Descubra o IP do computador, exemplo `192.168.1.50`:

```bash
flutter run --dart-define=API_URL=http://192.168.1.50/turnopronto_web/api/v1
```

Teste antes no navegador do celular:

```text
http://192.168.1.50/turnopronto_web/api/v1/health
```

Em produção será **HTTPS obrigatório**.

## Credencial de desenvolvimento

- usuário: `juliana@turnopronto.local`
- senha: a senha de demonstração que você definiu no `turnopronto_web/install.php`

O backend deve ter sido instalado pelo `turnopronto_web/install.php`.

## Observação iOS

Compilar/assinar o app iOS localmente requer macOS + Xcode. O mesmo código Flutter é usado nos dois sistemas.

## Próximas integrações nativas

- câmera para QR real
- geolocalização/GPS
- push notifications
- armazenamento seguro do token
- biometria
- deep links
- upload de documentos/selfie
- background task controlada para lembretes de turno

Veja [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md).

# Plano de desenvolvimento — `turnopronto_app`

## Objetivo

Entregar o aplicativo Android/iOS destinado ao **profissional**, mantendo comportamento e linguagem visual coerentes com o web e consumindo exclusivamente a API do `turnopronto_web`.

```text
Flutter Android/iOS
       |
       | HTTPS / JSON
       v
turnopronto_web /api/v1
       |
   regras + banco
```

O app **não terá banco de negócio próprio**. Cache local serve apenas para experiência/offline controlada.

---

## Fase A0 — Fundação — IMPLEMENTADA

- Flutter
- tema TurnoPronto
- navegação inferior
- serviço REST
- bearer token em memória
- modo demo
- modelos de oportunidade/turno
- tratamento básico de erro de API

## Fase A1 — Experiência principal — IMPLEMENTADA

### Início

- saudação
- confiabilidade
- oportunidades
- ganhos rápidos
- avaliação

### Vaga

- empresa
- reputação da empresa
- função
- data/horário
- valor
- endereço
- uniforme
- observações
- quantidade de candidatos
- aceite

### Turno

- status
- check-in
- PIN
- área de QR
- localização visual
- check-out
- valor do turno
- próximo repasse

### Navegação

- Início
- Turnos
- Agenda
- Ganhos
- Perfil

## Fase A2 — Autenticação segura

- refresh token ou sessão mobile equivalente;
- armazenamento em Keychain/Keystore;
- logout remoto;
- revogação por dispositivo;
- biometria opcional;
- recuperação de senha;
- dispositivo confiável.

## Fase A3 — Geolocalização e check-in real

Adicionar plugin de localização e permissões mínimas.

O check-in deve validar combinação de:

- horário;
- distância do local;
- QR/PIN;
- token do turno;
- dispositivo;
- timestamp do servidor.

Não confiar apenas no GPS do cliente.

## Fase A4 — QR Code

- scanner por câmera;
- QR efêmero ou assinado;
- expiração curta;
- prevenção de replay;
- fallback por PIN;
- log de método usado.

## Fase A5 — Push

Eventos prioritários:

- nova oportunidade compatível;
- vaga aceita;
- vaga alterada/cancelada;
- lembrete 24h;
- lembrete 2h;
- janela de check-in;
- pagamento liberado;
- disputa/ocorrência;
- documento expirando.

Push não substitui registro dentro do app.

## Fase A6 — Perfil/KYC

- CPF;
- documento;
- selfie/liveness via fornecedor;
- certificados;
- PIX;
- endereço;
- status de análise;
- reenvio quando recusado.

Dados sensíveis não devem ficar em cache aberto no telefone.

## Fase A7 — Reputação

Tela explicável com:

- confiabilidade;
- presença;
- pontualidade;
- conclusão;
- avaliações;
- ocorrências;
- prazo/peso da ocorrência;
- botão de contestação;
- status da revisão.

## Fase A8 — Cancelamentos

Fluxo deve mostrar **antes de confirmar**:

- tempo até o turno;
- eventual impacto na reputação;
- regra de compensação quando aplicável;
- opção de justificar/anexar evidência.

## Fase A9 — Ganhos e Pix

- saldo;
- valores a liberar;
- repasses;
- comissão/taxas quando houver;
- comprovantes;
- histórico;
- contestação.

Nenhuma informação financeira deve ser calculada apenas no app. O servidor é a fonte de verdade.

## Fase A10 — Release Android/iOS

### Android

- applicationId definitivo;
- ícones/splash;
- permissões;
- HTTPS/network security;
- assinatura release;
- Play Console;
- política de privacidade;
- Data Safety;
- testes internos/fechados.

### iOS

- bundle identifier;
- signing/certificates;
- capabilities;
- textos de permissão;
- App Store Connect;
- privacy manifests quando aplicáveis;
- TestFlight;
- revisão Apple.

---

## Definition of Done do app MVP

- login real;
- feed via API;
- detalhe via API;
- aceite idempotente;
- agenda real;
- check-in com GPS + QR/PIN;
- check-out;
- atualização de ganho;
- reputação explicável;
- push;
- token em armazenamento seguro;
- tratamento offline;
- Android testado em aparelho físico;
- iOS testado via TestFlight;
- crash reporting e logs sem dados sensíveis.

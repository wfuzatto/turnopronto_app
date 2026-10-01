# Integração com `turnopronto_web`

A URL é definida em build/runtime por `--dart-define=API_URL=...`.

Exemplo Android Emulator:

```bash
flutter run --dart-define=API_URL=http://10.0.2.2/turnopronto_web/api/v1
```

O login devolve um bearer token. O MVP atual mantém esse token em memória. A etapa de produção deve armazená-lo em Keychain/Keystore através de um plugin de secure storage.

## Fonte de verdade

Sempre servidor:

- disponibilidade da vaga;
- aceite;
- lotação;
- check-in;
- check-out;
- reputação;
- valores;
- repasses;
- disputas.

O app nunca deve decidir sozinho uma operação financeira ou penalidade.

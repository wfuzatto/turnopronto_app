# Integração com `turnopronto_web`

O aplicativo utiliza uma URL fixa de produção:

```text
https://turnopronto.com.br/api/v1
```

Não existe configuração de endereço, host, porta ou banco de dados no aplicativo. O cliente mobile se comunica somente por HTTPS/JSON com a API do TurnoPronto.

O banco MariaDB é acessado exclusivamente pelo backend `turnopronto_web`. Credenciais de banco nunca devem ser incluídas no APK.

O login devolve um bearer token. O MVP atual mantém esse token em memória. A etapa de produção deve armazená-lo em Keychain/Keystore através de um plugin de secure storage.

## Fonte de verdade

A API é responsável por:

- disponibilidade da vaga;
- aceite;
- lotação;
- check-in;
- check-out;
- reputação;
- valores;
- repasses;
- disputas.

O aplicativo não deve decidir sozinho operações financeiras, penalidades ou regras de negócio.

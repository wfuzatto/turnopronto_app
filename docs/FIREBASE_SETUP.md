# Cadastro do TurnoPronto no Firebase (Android)

## Dois aplicativos Android no mesmo projeto

A pipeline atual gera o projeto Android dinamicamente usando `flutter create --org br.com.turnopronto`. Cadastre **exatamente**:

- **TurnoPronto**: `br.com.turnopronto.turnopronto_app` (APK assinado, versão de teste/publicação).
- **TurnoPronto DEV**: `br.com.turnopronto.dev` (APK gerado quando não existe chave de assinatura persistente).

No [Firebase Console](https://console.firebase.google.com) crie o projeto `turnopronto` (se disponível) e adicione os dois apps pelo ícone Android. O Analytics é opcional para envio básico. O FCM HTTP v1 deve estar ativo.

Baixe um `google-services.json` **depois** de registrar ambos os pacotes e confirme que `client[]` contém os dois valores `client_info.android_client_info.package_name`. Este arquivo usa identificadores públicos do cliente — já a conta de serviço do backend é **secreta e completamente diferente**.

## Github Actions (Android)

No GitHub `wfuzatto/turnopronto_app` > Settings > Secrets and variables > Actions > New repository secret:

- Name: `FIREBASE_GOOGLE_SERVICES_JSON_BASE64`
- Value: conteúdo completo do `google-services.json`, codificado em Base64 em **uma única linha**, sem cabeçalhos.

Linux/macOS:
```sh
base64 -w 0 google-services.json
```
PowerShell no Windows:
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("google-services.json")) | Set-Clipboard
```

A pipeline extrai o JSON em `android/app/google-services.json` e só habilita o plugin Google Services quando o secret existe. Ela valida se o pacote do APK está cadastrado no JSON. **Nunca** coloque a chave da conta de serviço neste secret. Não envie chave privada ao app.

## Backend

Veja `wfuzatto/turnopronto_web/docs/FIREBASE_FCM.md`. É necessário configurar a conta de serviço Firebase no servidor PHP, aplicar a migração de tabelas (se CREATE não estiver permitido) e agendar cron **a cada minuto**.

## Funcionamento e testes

- Ao fazer login, o Android solicita autorização e registra o token FCM associado ao usuário autenticado.
- Mudanças de token são sincronizadas e o logout remove o token do banco.
- No sino da tela inicial, o profissional pode desativar/reativar os avisos.
- A criação de uma vaga com categoria compatível gera uma notificação interna e uma entrega na fila. O cron envia a push FCM HTTP v1 para o dispositivo.
- Tocar numa push abre os detalhes da vaga, inclusive após abrir o app do zero; se não existir mais, informa ao profissional.
- Com app aberto, surge aviso na tela com ação "Ver vaga"; com app em segundo plano/fechado, aparece notificação do sistema Android.
- Verifique token na tabela `tp_push_devices` e envio `tp_push_deliveries`; o Firebase não guarda a lista de profissões.

Para desenvolvimento local com shell Android já gerado, use o mesmo `google-services.json` em `android/app/`, com o plugin Google Services no Gradle. Para futura distribuição iOS é necessário cadastrar um app Apple e configurar APNs separadamente.

### Observações

Sem o secret do GitHub o app continua funcionando normalmente, mas mostra que as notificações estão indisponíveis. Sem a conta de serviço e o cron do servidor não há envio externo mesmo com token registrado. O APK precisa ser reconstruído após cadastrar o Firebase.

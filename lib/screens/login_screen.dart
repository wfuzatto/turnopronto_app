import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.api,
    required this.onLoggedIn,
  });

  final ApiService api;
  final VoidCallback onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(
    text: 'juliana@turnopronto.local',
  );
  final password = TextEditingController();
  late final TextEditingController server;
  bool loading = false;
  bool showServer = false;
  String? error;

  @override
  void initState() {
    super.initState();
    server = TextEditingController(text: widget.api.baseUrl);
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    server.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      widget.api.setBaseUrl(server.text);
      await widget.api.login(
        email.text.trim(),
        password.text,
      );
      if (mounted) widget.onLoggedIn();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void demo() {
    widget.api.loginDemo();
    widget.onLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: BrandLogo(),
                  ),
                  const SizedBox(height: 42),
                  const Text(
                    'Seu próximo extra\ncomeça aqui.',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      height: 1.08,
                      color: TpColors.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Escolha quando trabalhar. O TurnoPronto conecta seu tempo livre a oportunidades reais.',
                    style: TextStyle(
                      color: TpColors.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: Color(0xFFA12E38),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    onSubmitted: (_) => loading ? null : login(),
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => showServer = !showServer);
                    },
                    icon: const Icon(Icons.dns_outlined, size: 18),
                    label: Text(
                      showServer
                          ? 'Ocultar configuração do servidor'
                          : 'Configurar servidor / XAMPP',
                    ),
                  ),
                  if (showServer) ...[
                    TextField(
                      controller: server,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'URL da API',
                        helperText:
                            'Ex.: http://192.168.1.50/turnopronto_web/api/v1',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    onPressed: loading ? null : login,
                    child: Text(
                      loading ? 'Entrando...' : 'Entrar',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RegisterScreen(
                                  api: widget.api,
                                  onProfessionalRegistered:
                                      widget.onLoggedIn,
                                ),
                              ),
                            );
                          },
                    child: const Text('Ainda não tem conta? Criar cadastro'),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: demo,
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: const Text(
                      'Abrir demonstração sem servidor',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No celular físico, informe o IP do computador com XAMPP. O endereço 10.0.2.2 funciona apenas no emulador Android.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: TpColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

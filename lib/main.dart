import 'package:flutter/material.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TurnoProntoApp());
}

class TurnoProntoApp extends StatefulWidget {
  const TurnoProntoApp({super.key});

  @override
  State<TurnoProntoApp> createState() => _TurnoProntoAppState();
}

class _TurnoProntoAppState extends State<TurnoProntoApp> {
  final api = ApiService();
  final navigatorKey = GlobalKey<NavigatorState>();

  /// O login só é solicitado ao executar ações protegidas.
  /// A vaga selecionada permanece na pilha de navegação.
  Future<bool> requireLogin() async {
    if (api.authenticated) return true;
    final navigator = navigatorKey.currentState;
    if (navigator == null) return false;
    final result = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (loginContext) => LoginScreen(
          api: api,
          onLoggedIn: () {
            if (mounted) setState(() {});
            Navigator.of(loginContext).pop(true);
          },
        ),
      ),
    );
    return result == true && api.authenticated;
  }

  Future<void> onLogout() async {
    await api.logout();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'TurnoPronto',
      theme: turnoprontoTheme(),
      home: HomeShell(
        api: api,
        onLogout: onLogout,
        onRequireAuth: requireLogin,
      ),
    );
  }
}

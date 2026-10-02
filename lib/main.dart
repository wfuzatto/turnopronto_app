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
  bool loggedIn = false;

  void onLoggedIn() => setState(() => loggedIn = true);

  Future<void> onLogout() async {
    await api.logout();
    if (mounted) setState(() => loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TurnoPronto',
      theme: turnoprontoTheme(),
      home: loggedIn
          ? HomeShell(api: api, onLogout: onLogout)
          : LoginScreen(api: api, onLoggedIn: onLoggedIn),
    );
  }
}

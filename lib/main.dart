import 'dart:async';

import 'package:flutter/material.dart';
import 'screens/home_shell.dart';
import 'screens/job_detail_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
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
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final NotificationService notifications;

  @override
  void initState() {
    super.initState();
    notifications = NotificationService(
      api: api,
      onOpenShift: openNotifiedShift,
      onForegroundShift: (title, body, shiftId) {
        messengerKey.currentState?.showSnackBar(SnackBar(
          content: Text('$title — $body'),
          action: SnackBarAction(
            label: 'Ver vaga',
            onPressed: () => unawaited(openNotifiedShift(shiftId)),
          ),
          duration: const Duration(seconds: 7),
        ));
      },
    );
    unawaited(notifications.initialize());
  }

  Future<void> openNotifiedShift(int shiftId) async {
    try {
      final job = await api.job(shiftId);
      // O navegador precisa estar montado ao processar getInitialMessage.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        navigatorKey.currentState?.push(MaterialPageRoute<void>(
          builder: (_) => JobDetailScreen(
            api: api,
            job: job,
            onRequireAuth: requireLogin,
          ),
        ));
      });
    } catch (_) {
      messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Esta vaga não está mais disponível.')),
      );
    }
  }

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
            unawaited(notifications.sync());
            Navigator.of(loginContext).pop(true);
          },
        ),
      ),
    );
    return result == true && api.authenticated;
  }

  Future<void> onLogout() async {
    await notifications.unregister();
    await api.logout();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    notifications.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'TurnoPronto',
      theme: turnoprontoTheme(),
      home: HomeShell(
        api: api,
        notifications: notifications,
        onLogout: onLogout,
        onRequireAuth: requireLogin,
      ),
    );
  }
}

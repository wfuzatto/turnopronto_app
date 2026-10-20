import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

/// O cadastro e a segmentação ocorrem no backend TurnoPronto.
/// Firebase é utilizado somente para transporte das notificações.
class NotificationService extends ChangeNotifier {
  NotificationService({
    required this.api,
    required this.onOpenShift,
    required this.onForegroundShift,
  });

  final ApiService api;
  final Future<void> Function(int shiftId) onOpenShift;
  final void Function(String title, String body, int shiftId) onForegroundShift;

  FirebaseMessaging? _messaging;
  StreamSubscription<String>? _refreshSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  bool enabled = true;
  bool available = false;
  bool busy = false;
  String? error;
  String? _lastRegisteredToken;
  int? _lastRegisteredUserId;
  static const String _preferenceKey = 'turnopronto_new_job_push_enabled';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool(_preferenceKey) ?? true;
    notifyListeners();
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      available = true;
      notifyListeners();
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
      _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
        final id = int.tryParse(message.data['shift_id'] ?? '');
        if (id != null && id > 0 && enabled) {
          onForegroundShift(
            message.notification?.title ?? 'Nova vaga do seu interesse',
            message.notification?.body ?? 'Toque para ver os detalhes.',
            id,
          );
        }
      });
      _refreshSubscription = _messaging!.onTokenRefresh.listen((token) {
        unawaited(_sendToken(token));
      });
      final initial = await _messaging!.getInitialMessage();
      if (initial != null) _handleMessage(initial);
      await sync();
    } catch (_) {
      available = false;
      error = 'O Firebase ainda não está configurado neste APK.';
      notifyListeners();
    }
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data['type'] != 'matching_shift') return;
    final shiftId = int.tryParse(message.data['shift_id'] ?? '');
    if (shiftId != null && shiftId > 0) unawaited(onOpenShift(shiftId));
  }

  Future<void> sync() async {
    if (!available || _messaging == null || !enabled ||
        !api.authenticated || api.demoMode) return;
    final id = int.tryParse((api.currentUser?['id'] ?? '').toString());
    if (id == null) return;

    busy = true;
    error = null;
    notifyListeners();
    try {
      final permission = await _messaging!.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (permission.authorizationStatus != AuthorizationStatus.authorized &&
          permission.authorizationStatus != AuthorizationStatus.provisional) {
        error = 'Permita as notificações nas configurações do Android.';
        return;
      }
      final token = await _messaging!.getToken();
      if (token == null || token.isEmpty) {
        error = 'Não foi possível obter o token FCM.';
        return;
      }
      await _sendToken(token);
    } catch (_) {
      error = 'Não foi possível registrar este aparelho para receber vagas.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _sendToken(String token) async {
    if (!enabled || !available || !api.authenticated || api.demoMode) return;
    final userId = int.tryParse((api.currentUser?['id'] ?? '').toString());
    if (userId == null) return;
    if (_lastRegisteredToken == token && _lastRegisteredUserId == userId) return;
    try {
      await api.registerPushToken(
        token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
      _lastRegisteredToken = token;
      _lastRegisteredUserId = userId;
      error = null;
      notifyListeners();
    } catch (_) {
      error = 'Falha ao ativar os avisos no servidor do TurnoPronto.';
      notifyListeners();
    }
  }

  Future<void> setEnabled(bool next) async {
    enabled = next;
    (await SharedPreferences.getInstance()).setBool(_preferenceKey, next);
    notifyListeners();
    if (!next) {
      await unregister();
    } else {
      await sync();
    }
  }

  Future<void> unregister() async {
    if (_messaging == null) return;
    try {
      final token = _lastRegisteredToken ?? await _messaging!.getToken();
      if (token != null && api.authenticated && !api.demoMode) {
        await api.unregisterPushToken(token);
      }
    } catch (_) {
      // A revogação de acesso no app não deve ser bloqueada por perda de rede.
    } finally {
      _lastRegisteredToken = null;
      _lastRegisteredUserId = null;
    }
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    _openedSubscription?.cancel();
    _foregroundSubscription?.cancel();
    super.dispose();
  }
}

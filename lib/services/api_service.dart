import 'dart:convert';
import 'dart:io';
import '../models/job.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiService {
  ApiService();

  static const String _baseUrl = 'https://turnopronto.com.br/api/v1';

  String? token;
  bool demoMode = false;
  Map<String, dynamic>? currentUser;
  Map<String, dynamic>? currentProfile;

  String get baseUrl => _baseUrl;
  bool get authenticated => demoMode || (token != null && token!.isNotEmpty);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.openUrl(
        method,
        Uri.parse(_baseUrl + path),
      );
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (token != null) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer ' + token!,
        );
      }
      if (body != null) request.write(jsonEncode(body));

      final response = await request.close().timeout(
            const Duration(seconds: 20),
          );
      final raw = await response.transform(utf8.decoder).join();
      final dynamic decoded =
          raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw);
      if (decoded is! Map) {
        throw ApiException('Resposta inválida do TurnoPronto.');
      }
      final data = Map<String, dynamic>.from(decoded);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          data['ok'] == false) {
        throw ApiException(
          (data['error'] ?? ('Erro HTTP ' + response.statusCode.toString()))
              .toString(),
        );
      }
      return data;
    } on SocketException {
      throw ApiException('Não foi possível acessar o TurnoPronto agora.');
    } on HandshakeException {
      throw ApiException('Falha na conexão segura com o TurnoPronto.');
    } on FormatException {
      throw ApiException('O TurnoPronto respondeu em um formato inválido.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> health() async {
    if (demoMode) return;
    await _request('GET', '/health');
  }

  Future<List<Map<String, dynamic>>> categories() async {
    final data = await _request('GET', '/categories');
    final list = data['data'];
    if (list is! List) return <Map<String, dynamic>>[];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> startRegistration(
    Map<String, dynamic> payload,
  ) async {
    return _request('POST', '/auth/register/start', body: payload);
  }

  Future<Map<String, dynamic>> resendRegistration(
    String registrationId,
  ) async {
    return _request(
      'POST',
      '/auth/register/resend',
      body: {'registration_id': registrationId},
    );
  }

  Future<Map<String, dynamic>> verifyRegistration(
    String registrationId,
    String code,
  ) async {
    final data = await _request(
      'POST',
      '/auth/register/verify',
      body: {'registration_id': registrationId, 'code': code},
    );
    final user = data['user'];
    if (user is Map &&
        (user['role'] ?? '').toString() == 'professional' &&
        data['token'] != null) {
      token = data['token'].toString();
      currentUser = Map<String, dynamic>.from(user);
      demoMode = false;
      await me();
    }
    return data;
  }

  Future<void> login(String email, String password) async {
    final data = await _request(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    final user = data['user'];
    if (user is! Map) {
      throw ApiException('Usuário inválido na resposta.');
    }
    final normalizedUser = Map<String, dynamic>.from(user);
    if ((normalizedUser['role'] ?? '').toString() != 'professional') {
      throw ApiException('Este aplicativo é exclusivo para profissionais.');
    }
    token = data['token']?.toString();
    currentUser = normalizedUser;
    demoMode = false;
    await me();
  }

  void loginDemo() {
    demoMode = true;
    token = null;
    currentUser = {
      'id': 2,
      'name': 'Juliana Alves',
      'email': 'juliana@turnopronto.local',
      'role': 'professional',
    };
    currentProfile = {
      'headline': 'Garçom • Recepcionista',
      'city': 'São Paulo',
      'state': 'SP',
      'reliability_score': 97,
      'punctuality_score': 98,
      'attendance_score': 98,
      'rating': 4.9,
      'completed_shifts': 42,
      'status': 'verified',
    };
  }

  Future<void> logout() async {
    if (!demoMode && token != null) {
      try {
        await _request('POST', '/auth/logout');
      } catch (_) {}
    }
    token = null;
    demoMode = false;
    currentUser = null;
    currentProfile = null;
  }

  Future<Map<String, dynamic>> me() async {
    if (demoMode) {
      return {
        'user': currentUser ?? <String, dynamic>{},
        'profile': currentProfile ?? <String, dynamic>{},
      };
    }
    final data = await _request('GET', '/me');
    currentUser = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : <String, dynamic>{};
    currentProfile = data['profile'] is Map
        ? Map<String, dynamic>.from(data['profile'] as Map)
        : <String, dynamic>{};
    return {
      'user': currentUser!,
      'profile': currentProfile!,
    };
  }

  Future<List<Job>> opportunities() async {
    if (demoMode) return demoJobs();
    final data = await _request('GET', '/opportunities');
    final list = data['data'];
    if (list is! List) return <Job>[];
    return list
        .map(
          (e) => Job.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<Job> job(int id) async {
    if (demoMode) {
      return demoJobs().firstWhere(
        (e) => e.id == id,
        orElse: () => demoJobs().first,
      );
    }
    final data = await _request('GET', '/shifts/' + id.toString());
    return Job.fromJson(
      Map<String, dynamic>.from(data['data'] as Map),
    );
  }

  Future<AcceptResult> accept(int id) async {
    if (demoMode) {
      final selected = await job(id);
      return selected.requiresApproval
          ? const AcceptResult(status: 'applied')
          : AcceptResult(
              status: 'confirmed',
              assignmentId: 900 + id,
            );
    }
    final data = await _request(
      'POST',
      '/shifts/' + id.toString() + '/accept',
    );
    final rawId = data['assignment_id'];
    final assignmentId =
        rawId == null ? null : int.tryParse(rawId.toString());
    return AcceptResult(
      status: (data['status'] ??
              (assignmentId == null ? 'applied' : 'confirmed'))
          .toString(),
      assignmentId: assignmentId,
    );
  }

  Future<List<Assignment>> assignments() async {
    if (demoMode) return demoAssignments();
    final data = await _request('GET', '/assignments');
    final list = data['data'];
    if (list is! List) return <Assignment>[];
    return list
        .map(
          (e) => Assignment.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<Assignment> assignment(int id) async {
    if (demoMode) {
      return demoAssignments().firstWhere(
        (e) => e.id == id,
        orElse: () => demoAssignments().first,
      );
    }
    final data = await _request(
      'GET',
      '/assignments/' + id.toString(),
    );
    return Assignment.fromJson(
      Map<String, dynamic>.from(data['data'] as Map),
    );
  }

  Future<void> checkIn(
    int id, {
    required String pin,
  }) async {
    if (demoMode) return;
    await _request(
      'POST',
      '/assignments/' + id.toString() + '/check-in',
      body: {'pin': pin},
    );
  }

  Future<void> checkOut(int id) async {
    if (demoMode) return;
    await _request(
      'POST',
      '/assignments/' + id.toString() + '/check-out',
    );
  }

  Future<Map<String, dynamic>> earnings() async {
    if (demoMode) {
      return {
        'summary': {
          'total': 6420.0,
          'available': 780.0,
        },
        'months': [
          {'month': '2026-06', 'amount': 980.0},
          {'month': '2026-07', 'amount': 1250.0},
          {'month': '2026-08', 'amount': 1850.0},
          {'month': '2026-09', 'amount': 2340.0},
        ],
      };
    }
    final data = await _request('GET', '/earnings');
    return Map<String, dynamic>.from(data['data'] as Map);
  }

  Future<Map<String, dynamic>> reputation() async {
    if (demoMode) {
      return {
        'profile': currentProfile ?? <String, dynamic>{},
        'events': [
          {
            'id': 1,
            'description': 'Turno concluído com pontualidade.',
            'points_delta': 1,
            'severity': 'positive',
            'occurred_at': DateTime.now()
                .subtract(const Duration(days: 7))
                .toIso8601String(),
          },
        ],
      };
    }
    final data = await _request('GET', '/reputation');
    return Map<String, dynamic>.from(data['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> documents() async {
    if (demoMode) {
      return [
        {
          'label': 'Documento de identidade',
          'type': 'identity',
          'status': 'verified',
        },
        {
          'label': 'CPF',
          'type': 'cpf',
          'status': 'verified',
        },
        {
          'label': 'Comprovante de residência',
          'type': 'address',
          'status': 'verified',
        },
      ];
    }
    final data = await _request('GET', '/documents');
    final list = data['data'];
    if (list is! List) return [];
    return list
        .map(
          (e) => Map<String, dynamic>.from(e as Map),
        )
        .toList();
  }

  static List<Job> demoJobs() {
    final now = DateTime.now();
    DateTime d(int add, int h, [int m = 0]) =>
        DateTime(now.year, now.month, now.day + add, h, m);
    return [
      Job(
        id: 1,
        role: 'Garçom',
        company: 'Hotel Vale Eventos',
        startsAt: d(1, 18),
        endsAt: d(2, 2),
        value: 160,
        address: 'Av. das Nações Unidas, 12551',
        city: 'São Paulo',
        state: 'SP',
        dressCode: 'Calça preta, camisa branca e sapato social preto.',
        notes: 'Evento corporativo. Compareça com documento.',
        distanceKm: 2.1,
        acceptanceMode: 'automatic',
        requiredWorkers: 3,
      ),
      Job(
        id: 2,
        role: 'Recepcionista',
        company: 'SP Eventos',
        startsAt: d(2, 8),
        endsAt: d(2, 16),
        value: 180,
        address: 'Av. Paulista, 900',
        city: 'São Paulo',
        state: 'SP',
        dressCode: 'Social preto.',
        notes: 'Recepção e orientação de convidados.',
        companyRating: 4.8,
        candidates: 5,
        distanceKm: 3.4,
        acceptanceMode: 'manual',
        requiredWorkers: 2,
      ),
      Job(
        id: 3,
        role: 'Aux. Cozinha',
        company: 'Bistrô Central',
        startsAt: d(3, 14),
        endsAt: d(3, 22),
        value: 150,
        address: 'Rua Central, 50',
        city: 'São Paulo',
        state: 'SP',
        dressCode: 'Calçado fechado e calça preta.',
        notes: 'Apoio de preparação e organização.',
        companyRating: 4.7,
        candidates: 2,
        distanceKm: 1.8,
      ),
    ];
  }

  static List<Assignment> demoAssignments() {
    final selected = demoJobs().first;
    return [
      Assignment(
        id: 901,
        shiftId: selected.id,
        role: selected.role,
        company: selected.company,
        startsAt: selected.startsAt,
        endsAt: selected.endsAt,
        value: selected.value,
        status: 'confirmed',
        address: selected.address,
        city: selected.city,
        state: selected.state,
      ),
    ];
  }
}

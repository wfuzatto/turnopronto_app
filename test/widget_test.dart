import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turnopronto_app/models/job.dart';
import 'package:turnopronto_app/screens/home_shell.dart';
import 'package:turnopronto_app/screens/job_detail_screen.dart';
import 'package:turnopronto_app/services/api_service.dart';

class _PublicApi extends ApiService {
  @override
  Future<List<Job>> opportunities() async => ApiService.demoJobs();

  @override
  Future<Job> job(int id) async =>
      ApiService.demoJobs().firstWhere((item) => item.id == id);

  @override
  Future<Map<String, dynamic>> onboarding() async =>
      throw StateError('Visitante não pode consultar onboarding');

  @override
  Future<AcceptResult> accept(int id) async =>
      throw StateError('Visitante não pode se candidatar sem login');
}

void main() {
  testWidgets('visitante navega pelas vagas sem cadastro', (tester) async {
    final api = _PublicApi();
    var authRequests = 0;
    await tester.pumpWidget(MaterialApp(
      home: HomeShell(
        api: api,
        onLogout: () async {},
        onRequireAuth: () async {
          authRequests++;
          return false; // Login cancelado pelo visitante.
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Vagas perto de você'), findsOneWidget);
    expect(find.text('Garçom'), findsWidgets);

    await tester.tap(find.text('Meus turnos'));
    await tester.pumpAndSettle();
    expect(authRequests, 1);
    expect(find.text('Vagas perto de você'), findsOneWidget);

    await tester.tap(find.text('Ver todas').first);
    await tester.pumpAndSettle();
    expect(find.text('Todas as vagas'), findsOneWidget);
    expect(find.byKey(const Key('search-jobs')), findsOneWidget);
  });

  testWidgets('candidatura do visitante solicita autenticação primeiro',
      (tester) async {
    final api = _PublicApi();
    var authRequests = 0;
    await tester.pumpWidget(MaterialApp(
      home: JobDetailScreen(
        api: api,
        job: ApiService.demoJobs().first,
        onRequireAuth: () async {
          authRequests++;
          return false;
        },
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Candidatar-se'), findsOneWidget);
    await tester.tap(find.text('Candidatar-se'));
    await tester.pumpAndSettle();
    expect(authRequests, 1);
  });
}

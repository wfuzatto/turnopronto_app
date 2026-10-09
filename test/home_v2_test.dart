import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turnopronto_app/models/job.dart';
import 'package:turnopronto_app/screens/home_shell.dart';
import 'package:turnopronto_app/screens/home_screen.dart';
import 'package:turnopronto_app/services/api_service.dart';

class _FakeApi extends ApiService {
  _FakeApi() {
    currentUser = {'name': 'Wesley'};
  }

  @override
  Future<List<Job>> opportunities() async => const <Job>[];
}

void main() {
  testWidgets('Home V2 mostra título, navegação e chamada para vagas',
      (tester) async {
    final api = _FakeApi();
    await tester.pumpWidget(MaterialApp(home: HomeShell(
      api: api, onLogout: () async {},
    )));
    await tester.pumpAndSettle();
    expect(find.text('Olá, Wesley!'), findsOneWidget);
    expect(find.text('Vagas de trabalho\nperto de você.'), findsOneWidget);
    expect(find.text('Vagas perto de você'), findsOneWidget);
    expect(find.text('Mais vagas'), findsOneWidget);
    expect(find.text('Meus turnos'), findsWidgets);
    await tester.tap(find.text('Ver todas').first);
    await tester.pumpAndSettle();
    expect(find.text('Todas as vagas'), findsOneWidget);
    expect(find.byKey(const Key('search-jobs')), findsOneWidget);
  });

  testWidgets('Busca V2 oferece filtro real, sem lista duplicada',
      (tester) async {
    final api = _FakeApi();
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: HomeScreen(api: api, showAll: true),
    )));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('search-jobs')), 'garçom');
    await tester.pumpAndSettle();
    expect(find.text('0 vagas encontradas'), findsOneWidget);
  });
}

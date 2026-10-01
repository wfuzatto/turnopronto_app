import 'package:flutter_test/flutter_test.dart';
import 'package:turnopronto_app/main.dart';

void main() {
  testWidgets('abre a tela de login TurnoPronto', (tester) async {
    await tester.pumpWidget(const TurnoProntoApp());
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Seu próximo extra\ncomeça aqui.'), findsOneWidget);
  });
}

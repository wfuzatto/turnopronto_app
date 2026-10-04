import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turnopronto_app/screens/register_screen.dart';
import 'package:turnopronto_app/services/api_service.dart';

class _FakeApiService extends ApiService {
  @override
  Future<List<Map<String, dynamic>>> categories() async {
    return <Map<String, dynamic>>[
      <String, dynamic>{'id': 1, 'name': 'Garçom'},
    ];
  }
}

Finder fieldWithLabel(String label) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.labelText == label,
  );
}

Future<void> expectMasked(
  WidgetTester tester,
  String label,
  String raw,
  String expected,
) async {
  final finder = fieldWithLabel(label);
  expect(finder, findsOneWidget);
  await tester.enterText(finder, raw);
  await tester.pump();

  final field = tester.widget<TextField>(finder);
  expect(field.controller?.text, expected);
}

void main() {
  testWidgets('aplica máscaras no cadastro profissional', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(
          api: _FakeApiService(),
          onProfessionalRegistered: () {},
        ),
      ),
    );
    await tester.pump();

    await expectMasked(
      tester,
      'WhatsApp com DDD *',
      '35999998888',
      '(35) 99999-8888',
    );
    await expectMasked(
      tester,
      'CPF *',
      '12345678901',
      '123.456.789-01',
    );
    await expectMasked(
      tester,
      'RG *',
      '123456789',
      '12.345.678-9',
    );
    await expectMasked(
      tester,
      'CEP *',
      '37460000',
      '37460-000',
    );
    await expectMasked(
      tester,
      'CPF/CNPJ do titular Pix *',
      '12345678901',
      '123.456.789-01',
    );
  });

  testWidgets('aplica máscara de CNPJ no cadastro empresarial', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(
          api: _FakeApiService(),
          onProfessionalRegistered: () {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Empresa'));
    await tester.pump();

    await expectMasked(
      tester,
      'CPF do responsável *',
      '12345678901',
      '123.456.789-01',
    );
    await expectMasked(
      tester,
      'CNPJ *',
      '12345678000195',
      '12.345.678/0001-95',
    );
    await expectMasked(
      tester,
      'CPF/CNPJ do titular Pix *',
      '12345678000195',
      '12.345.678/0001-95',
    );
  });
}

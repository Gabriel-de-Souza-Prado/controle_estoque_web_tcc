import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/formulario_screen.dart';

Future<void> abrirOFormulario(WidgetTester tester) async {
  // A tela abaixo evita o caso do F5, que retorna à lista.
  await tester.pumpWidget(const MaterialApp(home: Scaffold()));
  Navigator.of(tester.element(find.byType(Scaffold)))
      .push(MaterialPageRoute(builder: (_) => const FormularioScreen()));
  await tester.pumpAndSettle();
}

Future<void> salvarFormulario(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Salvar'));
  await tester.tap(find.text('Salvar'));
  await tester.pump();
}

void main() {
  testWidgets('formulário vazio mostra os campos obrigatórios sem chamar API', (
    tester,
  ) async {
    // Não há Provider nem cliente HTTP: a validação precisa parar antes deles.
    await abrirOFormulario(tester);
    await salvarFormulario(tester);
    expect(find.text('Informe DTI'), findsOneWidget);
    expect(find.text('Informe Modelo'), findsOneWidget);
    expect(find.text('Informe Número de série'), findsOneWidget);
    expect(find.text('Informe Categoria'), findsOneWidget);
    expect(find.text('Informe Departamento'), findsOneWidget);
  });

  testWidgets('DTI válido passa e modelo curto continua recusado', (
    tester,
  ) async {
    await abrirOFormulario(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'DTI'), 'DTI001');
    await tester.enterText(find.widgetWithText(TextFormField, 'Modelo'), 'A');
    await salvarFormulario(tester);
    expect(find.text('Informe DTI'), findsNothing);
    expect(
      find.text('Modelo precisa ter pelo menos 2 caracteres'),
      findsOneWidget,
    );
    expect(find.byType(FormularioScreen), findsOneWidget);
  });
}

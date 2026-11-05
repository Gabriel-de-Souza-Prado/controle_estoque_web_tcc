import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:frontend/repositories/equipamento_repository.dart';
import 'package:frontend/screens/produtos_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/equipamento_service.dart';

import 'equipamentos_test.dart' show equipamento, sessao;

Future<void> abrirALista(WidgetTester tester, List<Object> itens) async {
  final auth = await sessao();
  final repositorio = EquipamentoRepository(
    cliente: MockClient((pedido) async {
      expect(pedido.method, 'GET');
      expect(pedido.url.path, '/equipamentos/');
      expect(pedido.headers['Authorization'], 'Bearer token-teste');
      return http.Response(
        jsonEncode(itens),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        Provider.value(value: EquipamentoService(repositorio, auth)),
      ],
      child: const MaterialApp(home: ProdutosScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista mostra o equipamento devolvido pela API simulada', (
    tester,
  ) async {
    await abrirALista(tester, [equipamento(modelo: 'Notebook Dell')]);
    expect(find.text('Notebook Dell'), findsOneWidget);
    expect(find.textContaining('DTI001'), findsOneWidget);
    expect(find.text('Nenhum equipamento cadastrado.'), findsNothing);
  });

  testWidgets('lista vazia avisa e mantém a opção de cadastrar', (
    tester,
  ) async {
    await abrirALista(tester, []);
    expect(find.text('Nenhum equipamento cadastrado.'), findsOneWidget);
    expect(find.byTooltip('Novo equipamento'), findsOneWidget);
  });
}

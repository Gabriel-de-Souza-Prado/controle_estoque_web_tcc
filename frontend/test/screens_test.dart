import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:frontend/main.dart';
import 'package:frontend/repositories/usuario_repository.dart';
import 'package:frontend/routes.dart';
import 'package:frontend/screens/cadastro_screen.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/perfil_screen.dart';
import 'package:frontend/screens/produtos_screen.dart';
import 'package:frontend/services/auth_service.dart';

// API de mentira: a senha certa é 'segredo123' e o token é 'token-da-ana'.
int pedidos = 0;

AuthService authDeMentira() {
  final cliente = MockClient((pedido) async {
    pedidos++;
    if (pedido.url.path == '/usuarios/login') {
      if (pedido.bodyFields['password'] == 'segredo123') {
        return http.Response(
          jsonEncode({'access_token': 'token-da-ana', 'token_type': 'bearer'}),
          200,
        );
      }
      return http.Response('{"detail": "E-mail ou senha incorretos"}', 401);
    }
    if (pedido.url.path == '/usuarios/eu' &&
        pedido.headers['Authorization'] == 'Bearer token-da-ana') {
      return http.Response(
        jsonEncode({'id': 1, 'nome': 'Ana', 'email': 'ana@estoque.com'}),
        200,
      );
    }
    return http.Response('{"detail": "Not authenticated"}', 401);
  });
  return AuthService(UsuarioRepository(cliente: cliente));
}

Widget appDeMentira(AuthService auth) {
  return ChangeNotifierProvider.value(value: auth, child: const MeuAppEstoque());
}

Future<void> preencherEEntrar(WidgetTester tester, String senha) async {
  await tester.enterText(find.byType(TextField).at(0), 'ana@estoque.com');
  await tester.enterText(find.byType(TextField).at(1), senha);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar no Sistema'));
  await tester.pumpAndSettle();
}

Future<void> abrirOMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a tela de login tem e-mail, senha e o botão Entrar', (tester) async {
    await tester.pumpWidget(appDeMentira(authDeMentira()));
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Entrar no Sistema'), findsOneWidget);
    expect(find.text('Não tem uma conta? Cadastre-se'), findsOneWidget);
  });

  testWidgets('a tela de cadastro tem nome, e-mail e senha', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: authDeMentira(),
        child: const MaterialApp(home: CadastroScreen()),
      ),
    );
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.widgetWithText(ElevatedButton, 'Cadastrar'), findsOneWidget);
  });

  testWidgets('com a senha certa, a rota /inicio abre a tela inicial', (tester) async {
    await tester.pumpWidget(appDeMentira(authDeMentira()));
    await preencherEEntrar(tester, 'segredo123');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Olá, Ana!'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('com a senha errada, fica no login e mostra o erro', (tester) async {
    final auth = authDeMentira();
    await tester.pumpWidget(appDeMentira(auth));
    await tester.enterText(find.byType(TextField).at(0), 'ana@estoque.com');
    await tester.enterText(find.byType(TextField).at(1), 'senha-errada');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar no Sistema'));
    // pumps manuais: o pumpAndSettle esperaria o aviso sumir sozinho
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(auth.logado, isFalse);
  });

  testWidgets('o link de cadastro abre o cadastro pelo nome da rota', (tester) async {
    await tester.pumpWidget(appDeMentira(authDeMentira()));
    await tester.tap(find.text('Não tem uma conta? Cadastre-se'));
    await tester.pumpAndSettle();
    expect(find.byType(CadastroScreen), findsOneWidget);
  });

  testWidgets('o guarda: sem sessão, a rota /inicio mostra o login', (tester) async {
    await tester.pumpWidget(appDeMentira(authDeMentira()));
    Navigator.of(tester.element(find.byType(LoginScreen))).pushNamed(AppRoutes.inicio);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('o menu mostra o nome sem receber nada pelo construtor', (tester) async {
    await tester.pumpWidget(appDeMentira(authDeMentira()));
    await preencherEEntrar(tester, 'segredo123');
    await abrirOMenu(tester);
    final menu = find.byType(Drawer);
    expect(find.descendant(of: menu, matching: find.text('Ana')), findsOneWidget);
    expect(find.descendant(of: menu, matching: find.text('ana@estoque.com')), findsOneWidget);
    await tester.tap(find.descendant(of: menu, matching: find.text('Perfil')));
    await tester.pumpAndSettle();
    expect(find.byType(PerfilScreen), findsOneWidget);
    await abrirOMenu(tester);
    expect(find.descendant(of: find.byType(Drawer), matching: find.text('Ana')), findsOneWidget);
  });

  testWidgets('sair volta ao login, limpa a pilha e apaga a sessão', (tester) async {
    final auth = authDeMentira();
    await tester.pumpWidget(appDeMentira(auth));
    await preencherEEntrar(tester, 'segredo123');
    await tester.tap(find.text('Ver os produtos'));
    await tester.pumpAndSettle();
    expect(find.byType(ProdutosScreen), findsOneWidget);
    await abrirOMenu(tester);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ProdutosScreen), findsNothing);
    expect(Navigator.of(tester.element(find.byType(LoginScreen))).canPop(), isFalse);
    expect(auth.logado, isFalse);
  });

  testWidgets('o watch redesenha a tela quando o service avisa', (tester) async {
    final auth = authDeMentira();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final nome = context.watch<AuthService>().usuarioAtual?.nome;
              return Text(nome ?? 'ninguém');
            },
          ),
        ),
      ),
    );
    expect(find.text('ninguém'), findsOneWidget);
    await auth.entrar('ana@estoque.com', 'segredo123');
    await tester.pump();
    expect(find.text('Ana'), findsOneWidget);
  });

  test('o service recusa campos vazios sem nem chamar a API', () async {
    final auth = authDeMentira();
    pedidos = 0;
    await expectLater(auth.entrar('', ''), throwsA(isA<Exception>()));
    expect(pedidos, 0);
    expect(auth.logado, isFalse);
  });

  test('entrar e sair mudam a sessão e avisam quem está de olho', () async {
    final auth = authDeMentira();
    var avisos = 0;
    auth.addListener(() => avisos++);
    await auth.entrar('ana@estoque.com', 'segredo123');
    expect(auth.token, 'token-da-ana');
    expect(auth.usuarioAtual?.nome, 'Ana');
    expect(avisos, 1);
    auth.logout();
    expect(auth.logado, isFalse);
    expect(auth.usuarioAtual, isNull);
    expect(avisos, 2);
  });
}
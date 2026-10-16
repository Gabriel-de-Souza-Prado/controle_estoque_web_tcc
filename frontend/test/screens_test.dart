import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/main.dart';
import 'package:frontend/repositories/usuario_repository.dart';
import 'package:frontend/routes.dart';
import 'package:frontend/screens/cadastro_screen.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/perfil_screen.dart';
import 'package:frontend/screens/produtos_screen.dart';
import 'package:frontend/services/auth_service.dart';

// Uma API de mentira, com um banco de mentira (o Map contas): responde como a
// de verdade, sem precisar do uvicorn. A Ana já tem conta, com a senha
// 'segredo123'. O token de cada conta é 'token-de-' e o e-mail dela.
// Ela conta quantos pedidos recebeu, para o teste do service conferir.
int pedidos = 0;

// O parâmetro guardado é o aparelho de mentira: o que o app tinha guardado da
// última vez que rodou. Por padrão, nada.
// O parâmetro apiFora simula o uvicorn parado: todo pedido falha sem resposta.
AuthService authDeMentira({
  Map<String, Object> guardado = const {},
  bool apiFora = false,
}) {
  SharedPreferences.setMockInitialValues(guardado);
  final contas = {
    'ana@estoque.com': {'nome': 'Ana', 'senha': 'segredo123'},
  };
  final cliente = MockClient((pedido) async {
    pedidos++;
    if (apiFora) {
      throw http.ClientException('Connection refused');
    }
    if (pedido.url.path == '/usuarios/' && pedido.method == 'POST') {
      final dados = jsonDecode(pedido.body);
      if (contas.containsKey(dados['email'])) {
        return http.Response(
          '{"detail": "Ja existe uma conta com o e-mail ${dados['email']}"}',
          409,
        );
      }
      if (dados['senha'].length < 6) {
        return http.Response(
          jsonEncode({
            'detail': [
              {
                'loc': ['body', 'senha'],
                'msg': 'String should have at least 6 characters',
              },
            ],
          }),
          422,
        );
      }
      contas[dados['email']] = {'nome': dados['nome'], 'senha': dados['senha']};
      return http.Response(
        jsonEncode({'id': 2, 'nome': dados['nome'], 'email': dados['email']}),
        201,
      );
    }
    if (pedido.url.path == '/usuarios/login') {
      final email = pedido.bodyFields['username'];
      if (contas[email]?['senha'] == pedido.bodyFields['password']) {
        return http.Response(
          jsonEncode({'access_token': 'token-de-$email', 'token_type': 'bearer'}),
          200,
        );
      }
      return http.Response('{"detail": "E-mail ou senha incorretos"}', 401);
    }
    if (pedido.url.path == '/usuarios/eu') {
      final email = (pedido.headers['Authorization'] ?? '').replaceFirst(
        'Bearer token-de-',
        '',
      );
      if (contas.containsKey(email)) {
        return http.Response(
          jsonEncode({'id': 1, 'nome': contas[email]!['nome'], 'email': email}),
          200,
        );
      }
    }
    return http.Response('{"detail": "Token invalido ou vencido"}', 401);
  });
  return AuthService(UsuarioRepository(cliente: cliente));
}

// O app de verdade, com a sessão de mentira no topo, como o main.dart faz.
// O .value entrega ao Provider um objeto que já existe, em vez de criá-lo.
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

// Abre o cadastro pelo link do login e preenche os três campos.
Future<void> preencherECadastrar(
  WidgetTester tester,
  String email,
  String senha,
) async {
  await tester.tap(find.text('Não tem uma conta? Cadastre-se'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).at(0), 'Bia');
  await tester.enterText(find.byType(TextField).at(1), email);
  await tester.enterText(find.byType(TextField).at(2), senha);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Cadastrar'));
  await tester.pumpAndSettle();
}

// O que o aparelho de mentira tem guardado como token (ou null).
Future<String?> tokenGuardado() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

// Confere que o cadastro foi recusado, com esta frase para a tela.
Matcher recusadoCom(String frase) {
  return throwsA(isA<ErroDeCadastro>().having((e) => e.mensagem, 'mensagem', frase));
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

  testWidgets('cadastrar pela tela cria a conta e abre a tela inicial', (tester) async {
    await tester.pumpWidget(appDeMentira(authDeMentira()));
    await preencherECadastrar(tester, 'bia@estoque.com', 'segredo456');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Olá, Bia!'), findsOneWidget);
    expect(find.byType(CadastroScreen), findsNothing);
  });

  testWidgets('e-mail repetido: a tela mostra o erro e fica no cadastro', (tester) async {
    await tester.pumpWidget(appDeMentira(authDeMentira()));
    await preencherECadastrar(tester, 'ana@estoque.com', 'segredo456');
    expect(find.text('Já existe uma conta com este e-mail.'), findsOneWidget);
    expect(find.byType(CadastroScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('o link Já tenho conta leva ao login', (tester) async {
    await tester.pumpWidget(appDeMentira(authDeMentira()));
    await tester.tap(find.text('Não tem uma conta? Cadastre-se'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Já tenho conta'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(CadastroScreen), findsNothing);
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
    expect(await tokenGuardado(), 'token-de-ana@estoque.com');
    await abrirOMenu(tester);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ProdutosScreen), findsNothing);
    expect(Navigator.of(tester.element(find.byType(LoginScreen))).canPop(), isFalse);
    expect(auth.logado, isFalse);
    expect(await tokenGuardado(), isNull);
  });

  testWidgets('com a sessão restaurada, o app abre direto na tela inicial', (tester) async {
    final auth = authDeMentira(guardado: {'token': 'token-de-ana@estoque.com'});
    await auth.restaurar();
    await tester.pumpWidget(appDeMentira(auth));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Olá, Ana!'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
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

  // O service testado sozinho, sem tela nenhuma: é o que as camadas compram.
  test('o service recusa campos vazios sem nem chamar a API', () async {
    final auth = authDeMentira();
    pedidos = 0;
    await expectLater(auth.entrar('', ''), throwsA(isA<ErroDeLogin>()));
    await expectLater(
      auth.cadastrar('', '', ''),
      recusadoCom('Preencha o nome, o e-mail e a senha.'),
    );
    expect(pedidos, 0);
    expect(auth.logado, isFalse);
  });

  test('entrar e sair mudam a sessão e avisam quem está de olho', () async {
    final auth = authDeMentira();
    var avisos = 0;
    auth.addListener(() => avisos++);
    await auth.entrar('ana@estoque.com', 'segredo123');
    expect(auth.token, 'token-de-ana@estoque.com');
    expect(auth.usuarioAtual?.nome, 'Ana');
    expect(avisos, 1);
    await auth.sair();
    expect(auth.logado, isFalse);
    expect(auth.usuarioAtual, isNull);
    expect(avisos, 2);
  });

  test('cadastrar cria a conta e já entra com ela, pelo mesmo caminho do login', () async {
    final auth = authDeMentira();
    await auth.cadastrar('Bia', 'bia@estoque.com', 'segredo456');
    expect(auth.logado, isTrue);
    expect(auth.usuarioAtual?.nome, 'Bia');
    expect(auth.token, 'token-de-bia@estoque.com');
  });

  test('o service traduz a recusa da API: e-mail repetido (409) e campo inválido (422)', () async {
    final auth = authDeMentira();
    await expectLater(
      auth.cadastrar('Ana', 'ana@estoque.com', 'segredo123'),
      recusadoCom('Já existe uma conta com este e-mail.'),
    );
    await expectLater(
      auth.cadastrar('Bia', 'bia@estoque.com', '123'),
      recusadoCom('senha: String should have at least 6 characters'),
    );
    expect(auth.logado, isFalse);
    expect(await tokenGuardado(), isNull);
  });

  test('entrar guarda o token no aparelho', () async {
    final auth = authDeMentira();
    await auth.entrar('ana@estoque.com', 'segredo123');
    expect(await tokenGuardado(), 'token-de-ana@estoque.com');
  });

  test('restaurar devolve a sessão a quem tem um token guardado', () async {
    final auth = authDeMentira(guardado: {'token': 'token-de-ana@estoque.com'});
    pedidos = 0;
    await auth.restaurar();
    expect(auth.logado, isTrue);
    expect(auth.usuarioAtual?.nome, 'Ana');
    expect(pedidos, 1);
  });

  test('restaurar sem token guardado não pede nada à API', () async {
    final auth = authDeMentira();
    pedidos = 0;
    await auth.restaurar();
    expect(auth.logado, isFalse);
    expect(pedidos, 0);
  });

  test('restaurar apaga o token que a API não aceita mais', () async {
    final auth = authDeMentira(guardado: {'token': 'token-vencido'});
    await auth.restaurar();
    expect(auth.logado, isFalse);
    expect(await tokenGuardado(), isNull);
  });

  test('sair apaga o token guardado no aparelho', () async {
    final auth = authDeMentira(guardado: {'token': 'token-de-ana@estoque.com'});
    await auth.restaurar();
    expect(auth.logado, isTrue);
    await auth.sair();
    expect(await tokenGuardado(), isNull);
  });

  // Extra, além dos 22 do roteiro: o uvicorn parado não pode apagar o token.
  test('restaurar com a API fora do ar mantém o token guardado', () async {
    final auth = authDeMentira(
      guardado: {'token': 'token-de-ana@estoque.com'},
      apiFora: true,
    );
    await auth.restaurar();
    expect(auth.logado, isFalse);
    expect(await tokenGuardado(), 'token-de-ana@estoque.com');
  });
}
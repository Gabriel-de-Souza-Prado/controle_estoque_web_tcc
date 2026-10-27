import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/equipamento_model.dart';
import 'package:frontend/repositories/equipamento_repository.dart';
import 'package:frontend/repositories/usuario_repository.dart';
import 'package:frontend/routes.dart';
import 'package:frontend/screens/equipamento_screen.dart';
import 'package:frontend/screens/formulario_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/produtos_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/equipamento_service.dart';

const dados = DadosEquipamento(
  dti: 'DTI003',
  modelo: 'Teclado USB',
  numeroSerie: 'SERIE003',
  categoria: 'Periférico',
  status: 'No Estoque',
  departamento: 'Suporte',
);

Map<String, dynamic> equipamento({
  int id = 1,
  String modelo = 'Notebook Dell',
}) => {
  'id': id,
  'dti': 'DTI00$id',
  'modelo': modelo,
  'numero_serie': 'SERIE00$id',
  'categoria': 'Informática',
  'status': 'No Estoque',
  'departamento': 'Suporte',
  'observacao': null,
  'dono_id': 1,
};

/// Guarda os pedidos e simula persistência: a lista só muda via POST/PATCH/DELETE.
class EstoqueSimulado {
  final itens = [equipamento(), equipamento(id: 2, modelo: 'Monitor LG')];
  final pedidos = <http.Request>[];
  String? metodoRecusado;
  int codigoRecusa = 409;
  Object detalhe = 'Operação recusada pela API.';
  Completer<void>? aguardarGravacao;

  late final cliente = MockClient((pedido) async {
    pedidos.add(pedido);
    expect(pedido.headers['Authorization'], 'Bearer token-teste');
    if (pedido.method == metodoRecusado) {
      return http.Response(
        jsonEncode({'detail': detalhe}),
        codigoRecusa,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    final segmentos = pedido.url.pathSegments
        .where((s) => s.isNotEmpty)
        .toList();
    if (segmentos.length == 1 && pedido.method == 'GET') {
      return resposta(itens, 200);
    }
    if (pedido.method == 'POST') {
      if (aguardarGravacao != null) await aguardarGravacao!.future;
      final corpo = jsonDecode(pedido.body) as Map<String, dynamic>;
      if (itens.any((item) => item['dti'] == corpo['dti'])) {
        return resposta({
          'detail': 'Já existe um equipamento com este DTI.',
        }, 409);
      }
      final novo = {...corpo, 'id': 3, 'dono_id': 1};
      itens.add(novo);
      return resposta(novo, 201);
    }
    final id = int.parse(segmentos.last);
    final indice = itens.indexWhere((item) => item['id'] == id);
    if (indice < 0) {
      return resposta({'detail': 'Equipamento não encontrado'}, 404);
    }
    if (pedido.method == 'PATCH') {
      itens[indice].addAll(jsonDecode(pedido.body) as Map<String, dynamic>);
    } else if (pedido.method == 'DELETE') {
      itens.removeAt(indice);
      return http.Response('', 204);
    }
    return resposta(itens[indice], 200);
  });

  static http.Response resposta(Object corpo, int codigo) => http.Response(
    jsonEncode(corpo),
    codigo,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

Future<AuthService> sessao({bool entrar = true}) async {
  SharedPreferences.setMockInitialValues({});
  final auth = AuthService(
    UsuarioRepository(
      cliente: MockClient((pedido) async {
        if (pedido.url.path.endsWith('/login')) {
          return EstoqueSimulado.resposta({'access_token': 'token-teste'}, 200);
        }
        return EstoqueSimulado.resposta({
          'id': 1,
          'nome': 'Ana',
          'email': 'ana@estoque.com',
        }, 200);
      }),
    ),
  );
  if (entrar) await auth.entrar('ana@estoque.com', 'segredo123');
  return auth;
}

Future<void> abrirEstoque(WidgetTester tester, EstoqueSimulado estoque) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: await sessao(),
      child: MeuAppEstoque(
        equipamentoRepository: EquipamentoRepository(cliente: estoque.cliente),
      ),
    ),
  );
  await tester.tap(find.text('Ver os produtos'));
  await tester.pumpAndSettle();
}

Finder campo(String rotulo) => find.widgetWithText(TextFormField, rotulo);

Future<void> preencher(WidgetTester tester, {String dti = 'DTI003'}) async {
  await tester.tap(find.byTooltip('Novo equipamento'));
  await tester.pumpAndSettle();
  for (final entrada in {
    'DTI': dti,
    'Modelo': 'Teclado USB',
    'Número de série': 'SERIE003',
    'Categoria': 'Periférico',
    'Departamento': 'Suporte',
  }.entries) {
    await tester.ensureVisible(campo(entrada.key));
    await tester.enterText(campo(entrada.key), entrada.value);
  }
}

Future<void> salvar(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Salvar'));
  await tester.tap(find.text('Salvar'));
  await tester.pumpAndSettle();
}

Future<void> responderExclusao(WidgetTester tester, String escolha) async {
  await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Excluir'));
  await tester.tap(find.widgetWithText(OutlinedButton, 'Excluir'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: find.byType(AlertDialog), matching: find.text(escolha)),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('listar envia o token e converte JSON em modelos', () async {
    final estoque = EstoqueSimulado();
    final lista = await EquipamentoRepository(cliente: estoque.cliente)
        .listar('token-teste');
    expect(lista, hasLength(2));
    expect(lista.first, isA<EquipamentoModel>());
    expect(lista.first.dti, 'DTI001');
    expect(estoque.pedidos.single.url.path, '/equipamentos/');
  });

  test('buscar usa o id no endereço e devolve o equipamento atual', () async {
    final estoque = EstoqueSimulado();
    final item = await EquipamentoRepository(cliente: estoque.cliente)
        .buscar('token-teste', 2);
    expect(item.modelo, 'Monitor LG');
    expect(estoque.pedidos.single.url.path, '/equipamentos/2');
  });

  test('POST envia os campos do schema sem inventar id ou dono', () async {
    final estoque = EstoqueSimulado();
    final item = await EquipamentoRepository(cliente: estoque.cliente)
        .criar('token-teste', dados);
    final pedido = estoque.pedidos.single;
    expect(pedido.method, 'POST');
    expect(pedido.url.path, '/equipamentos/');
    expect(pedido.headers['Content-Type'], startsWith('application/json'));
    expect(jsonDecode(pedido.body), {
      'dti': 'DTI003',
      'modelo': 'Teclado USB',
      'numero_serie': 'SERIE003',
      'categoria': 'Periférico',
      'status': 'No Estoque',
      'departamento': 'Suporte',
      'observacao': null,
    });
    expect(item.id, 3);
  });

  test('PATCH envia os dados e DELETE aceita 204 vazio', () async {
    final estoque = EstoqueSimulado();
    final repo = EquipamentoRepository(cliente: estoque.cliente);
    await repo.atualizar('token-teste', 1, dados);
    await repo.excluir('token-teste', 1);
    expect(estoque.pedidos.map((p) => '${p.method} ${p.url.path}'), [
      'PATCH /equipamentos/1',
      'DELETE /equipamentos/1',
    ]);
    final corpo = jsonDecode(estoque.pedidos.first.body) as Map;
    expect(corpo.containsKey('id'), isFalse);
    expect(corpo.containsKey('dono_id'), isFalse);
    expect(estoque.itens, hasLength(1));
  });

  test('todas as operações exigem sessão antes de chamar a API', () async {
    final estoque = EstoqueSimulado();
    final service = EquipamentoService(
      EquipamentoRepository(cliente: estoque.cliente),
      await sessao(entrar: false),
    );
    for (final operacao in <Future<Object?> Function()>[
      service.listar,
      () => service.buscar(1),
      () => service.criar(dados),
      () => service.atualizar(1, dados),
      () async {
        await service.excluir(1);
        return null;
      },
    ]) {
      await expectLater(operacao(), throwsA(isA<ErroDeEquipamentos>()));
    }
    expect(estoque.pedidos, isEmpty);
  });

  test('o serviço traduz 422 removendo o prefixo Value error', () async {
    final estoque = EstoqueSimulado()
      ..metodoRecusado = 'POST'
      ..codigoRecusa = 422
      ..detalhe = [
        {
          'loc': ['body', 'dti'],
          'msg': 'Value error, DTI inválido',
        },
      ];
    final service = EquipamentoService(
      EquipamentoRepository(cliente: estoque.cliente),
      await sessao(),
    );
    await expectLater(
      service.criar(dados),
      throwsA(
        isA<ErroDeEquipamentos>().having(
          (e) => e.mensagem,
          'mensagem',
          'dti: DTI inválido',
        ),
      ),
    );
  });

  test('falha de rede vira mensagem do serviço', () async {
    final service = EquipamentoService(
      EquipamentoRepository(
        cliente: MockClient((_) async => throw http.ClientException('offline')),
      ),
      await sessao(),
    );
    await expectLater(
      service.excluir(1),
      throwsA(
        isA<ErroDeEquipamentos>().having(
          (e) => e.mensagem,
          'mensagem',
          contains('API'),
        ),
      ),
    );
  });

  test('resposta de erro sem JSON usa mensagem de fallback', () async {
    final repo = EquipamentoRepository(
      cliente: MockClient(
        (_) async => http.Response('Internal Server Error', 500),
      ),
    );
    await expectLater(
      repo.criar('token', dados),
      throwsA(
        isA<RecusaDaApi>().having(
          (e) => e.mensagem,
          'mensagem',
          'Erro inesperado da API.',
        ),
      ),
    );
  });

  testWidgets('lista mostra os equipamentos vindos da API', (tester) async {
    await abrirEstoque(tester, EstoqueSimulado());
    expect(find.text('Notebook Dell'), findsOneWidget);
    expect(find.text('Monitor LG'), findsOneWidget);
  });

  testWidgets('lista vazia continua permitindo criar', (tester) async {
    await abrirEstoque(tester, EstoqueSimulado()..itens.clear());
    expect(find.text('Nenhum equipamento cadastrado.'), findsOneWidget);
    expect(find.byTooltip('Novo equipamento'), findsOneWidget);
  });

  testWidgets('erro da lista e nova tentativa', (tester) async {
    final estoque = EstoqueSimulado()..metodoRecusado = 'GET';
    await abrirEstoque(tester, estoque);
    expect(find.text('Operação recusada pela API.'), findsOneWidget);
    estoque.metodoRecusado = null;
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();
    expect(find.text('Notebook Dell'), findsOneWidget);
  });

  testWidgets('detalhe busca pelo id, sem reaproveitar dado antigo da lista', (
    tester,
  ) async {
    final estoque = EstoqueSimulado();
    await abrirEstoque(tester, estoque);
    estoque.itens.first['modelo'] = 'Notebook atualizado';
    await tester.tap(find.text('Notebook Dell'));
    await tester.pumpAndSettle();
    expect(find.text('Notebook atualizado'), findsOneWidget);
    expect(estoque.pedidos.last.url.path, '/equipamentos/1');
  });

  testWidgets('o + cria e a lista é buscada novamente', (tester) async {
    final estoque = EstoqueSimulado();
    await abrirEstoque(tester, estoque);
    await preencher(tester);
    expect(find.text('Novo equipamento'), findsOneWidget);
    await salvar(tester);
    expect(find.byType(FormularioScreen), findsNothing);
    expect(find.text('Teclado USB'), findsOneWidget);
    expect(estoque.pedidos.last.method, 'GET');
    expect(estoque.pedidos.where((p) => p.method == 'POST'), hasLength(1));
  });

  testWidgets('voltar do formulário não grava nem recarrega a lista', (
    tester,
  ) async {
    final estoque = EstoqueSimulado();
    await abrirEstoque(tester, estoque);
    await preencher(tester);
    final quantidade = estoque.pedidos.length;
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ProdutosScreen), findsOneWidget);
    expect(estoque.pedidos, hasLength(quantidade));
  });

  testWidgets('campos vazios e curtos não geram pedidos', (tester) async {
    final estoque = EstoqueSimulado();
    await abrirEstoque(tester, estoque);
    await tester.tap(find.byTooltip('Novo equipamento'));
    await tester.pumpAndSettle();
    estoque.pedidos.clear();
    await salvar(tester);
    expect(find.text('Informe DTI'), findsOneWidget);
    expect(find.text('Informe Modelo'), findsOneWidget);
    await tester.ensureVisible(campo('DTI'));
    await tester.enterText(campo('DTI'), 'AB');
    await salvar(tester);
    expect(
      find.text('DTI precisa ter pelo menos 3 caracteres'),
      findsOneWidget,
    );
    expect(estoque.pedidos, isEmpty);
  });

  testWidgets('manutenção exige observação no formulário', (tester) async {
    final estoque = EstoqueSimulado();
    await abrirEstoque(tester, estoque);
    await preencher(tester);
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Em Manutenção').last);
    await tester.pumpAndSettle();
    estoque.pedidos.clear();
    await salvar(tester);
    expect(find.text('Informe a observação para manutenção'), findsOneWidget);
    expect(estoque.pedidos, isEmpty);
    await tester.enterText(campo('Observação'), 'Trocar a fonte');
    await salvar(tester);
    expect(estoque.itens.last['status'], 'Em Manutenção');
    expect(estoque.itens.last['observacao'], 'Trocar a fonte');
  });

  testWidgets('DTI repetido mostra o 409 e preserva os campos', (tester) async {
    await abrirEstoque(tester, EstoqueSimulado());
    await preencher(tester, dti: 'DTI001');
    await salvar(tester);
    expect(find.text('Já existe um equipamento com este DTI.'), findsOneWidget);
    expect(find.byType(FormularioScreen), findsOneWidget);
    expect(
      tester.widget<TextFormField>(campo('Modelo')).controller!.text,
      'Teclado USB',
    );
  });

  testWidgets('422 da API mantém formulário aberto e permite corrigir', (
    tester,
  ) async {
    final estoque = EstoqueSimulado()
      ..metodoRecusado = 'POST'
      ..codigoRecusa = 422
      ..detalhe = [
        {
          'loc': ['body', 'dti'],
          'msg': 'Value error, DTI inválido',
        },
      ];
    await abrirEstoque(tester, estoque);
    await preencher(tester);
    await salvar(tester);
    expect(find.text('dti: DTI inválido'), findsOneWidget);
    expect(find.byType(FormularioScreen), findsOneWidget);
    estoque.metodoRecusado = null;
    await salvar(tester);
    expect(find.text('Teclado USB'), findsOneWidget);
  });

  testWidgets('editar usa o mesmo formulário e devolve a lista atualizada', (
    tester,
  ) async {
    final estoque = EstoqueSimulado();
    await abrirEstoque(tester, estoque);
    await tester.tap(find.text('Notebook Dell'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar equipamento'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(campo('DTI')).controller!.text,
      'DTI001',
    );
    await tester.enterText(campo('Modelo'), 'Notebook Lenovo');
    await salvar(tester);
    expect(find.byType(FormularioScreen), findsNothing);
    expect(find.byType(EquipamentoScreen), findsNothing);
    expect(find.text('Notebook Lenovo'), findsOneWidget);
    expect(estoque.pedidos.where((p) => p.method == 'PATCH'), hasLength(1));
  });

  testWidgets('cancelar edição volta ao detalhe sem PATCH', (tester) async {
    final estoque = EstoqueSimulado();
    await abrirEstoque(tester, estoque);
    await tester.tap(find.text('Notebook Dell'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(EquipamentoScreen), findsOneWidget);
    expect(estoque.pedidos.where((p) => p.method == 'PATCH'), isEmpty);
  });

  testWidgets(
    'excluir pergunta: cancelar preserva, confirmar remove e atualiza',
    (tester) async {
      final estoque = EstoqueSimulado();
      await abrirEstoque(tester, estoque);
      await tester.tap(find.text('Notebook Dell'));
      await tester.pumpAndSettle();
      await responderExclusao(tester, 'Cancelar');
      expect(estoque.pedidos.where((p) => p.method == 'DELETE'), isEmpty);
      expect(find.byType(EquipamentoScreen), findsOneWidget);
      await responderExclusao(tester, 'Excluir');
      expect(find.byType(EquipamentoScreen), findsNothing);
      expect(find.text('Notebook Dell'), findsNothing);
      expect(find.text('Monitor LG'), findsOneWidget);
      expect(estoque.pedidos.last.method, 'GET');
    },
  );

  testWidgets('exclusão recusada mantém detalhe e mostra a frase da API', (
    tester,
  ) async {
    final estoque = EstoqueSimulado()..metodoRecusado = 'DELETE';
    await abrirEstoque(tester, estoque);
    await tester.tap(find.text('Notebook Dell'));
    await tester.pumpAndSettle();
    await responderExclusao(tester, 'Excluir');
    expect(find.byType(EquipamentoScreen), findsOneWidget);
    expect(find.text('Operação recusada pela API.'), findsOneWidget);
    expect(estoque.itens, hasLength(2));
  });

  testWidgets('F5 no formulário mostra a lista', (tester) async {
    await abrirEstoque(tester, EstoqueSimulado());
    Navigator.of(tester.element(find.byType(ProdutosScreen)))
        .pushNamedAndRemoveUntil(AppRoutes.formulario, (_) => false);
    await tester.pumpAndSettle();
    expect(find.text('Novo equipamento'), findsNothing);
    expect(find.text('Notebook Dell'), findsOneWidget);
  });

  testWidgets('detalhe sem argumentos mostra a lista', (tester) async {
    await abrirEstoque(tester, EstoqueSimulado());
    Navigator.of(tester.element(find.byType(ProdutosScreen)))
        .pushNamed(AppRoutes.equipamento);
    await tester.pumpAndSettle();
    expect(find.text('Notebook Dell'), findsWidgets);
  });

  testWidgets('rota do formulário exige sessão', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: await sessao(entrar: false),
        child: const MeuAppEstoque(),
      ),
    );
    Navigator.of(tester.element(find.byType(LoginScreen)))
        .pushNamed(AppRoutes.formulario);
    await tester.pumpAndSettle();
    expect(find.byType(FormularioScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('salvar bloqueia novo envio enquanto a API trabalha', (
    tester,
  ) async {
    final estoque = EstoqueSimulado()..aguardarGravacao = Completer<void>();
    await abrirEstoque(tester, estoque);
    await preencher(tester);
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Salvando...'),
          )
          .onPressed,
      isNull,
    );
    expect(estoque.pedidos.where((p) => p.method == 'POST'), hasLength(1));
    estoque.aguardarGravacao!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Teclado USB'), findsOneWidget);
  });
}

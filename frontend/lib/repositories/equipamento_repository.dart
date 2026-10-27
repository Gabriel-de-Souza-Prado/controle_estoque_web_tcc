import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/equipamento_model.dart';
import 'usuario_repository.dart';

/// Centraliza os pedidos HTTP da entidade equipamento.
class EquipamentoRepository {
  EquipamentoRepository({http.Client? cliente})
    : cliente = cliente ?? http.Client();

  final http.Client cliente;

  Future<List<EquipamentoModel>> listar(String token) async {
    final resposta = await cliente.get(
      Uri.parse('$enderecoDaApi/equipamentos/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resposta.statusCode != 200) {
      throw RecusaDaApi(resposta.statusCode, _mensagemErro(resposta.body));
    }

    final itens = jsonDecode(resposta.body) as List<dynamic>;

    return [
      for (final item in itens)
        EquipamentoModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<EquipamentoModel> buscar(String token, int id) async {
    final resposta = await cliente.get(
      Uri.parse('$enderecoDaApi/equipamentos/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resposta.statusCode != 200) {
      throw RecusaDaApi(resposta.statusCode, _mensagemErro(resposta.body));
    }

    return EquipamentoModel.fromJson(
      jsonDecode(resposta.body) as Map<String, dynamic>,
    );
  }

  Future<EquipamentoModel> criar(String token, DadosEquipamento dados) async {
    final resposta = await cliente.post(
      Uri.parse('$enderecoDaApi/equipamentos/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(_corpo(dados)),
    );
    return _equipamentoDaResposta(resposta, 201);
  }

  Future<EquipamentoModel> atualizar(
    String token,
    int id,
    DadosEquipamento dados,
  ) async {
    final resposta = await cliente.patch(
      Uri.parse('$enderecoDaApi/equipamentos/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(_corpo(dados)),
    );
    return _equipamentoDaResposta(resposta, 200);
  }

  Future<void> excluir(String token, int id) async {
    final resposta = await cliente.delete(
      Uri.parse('$enderecoDaApi/equipamentos/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resposta.statusCode != 204) {
      throw RecusaDaApi(resposta.statusCode, _mensagemErro(resposta.body));
    }
    // O 204 não tem corpo: não tentamos decodificar JSON.
  }

  Map<String, Object?> _corpo(DadosEquipamento dados) => {
    'dti': dados.dti,
    'modelo': dados.modelo,
    'numero_serie': dados.numeroSerie,
    'categoria': dados.categoria,
    'status': dados.status,
    'departamento': dados.departamento,
    'observacao': dados.observacao,
  };

  EquipamentoModel _equipamentoDaResposta(
    http.Response resposta,
    int esperado,
  ) {
    if (resposta.statusCode != esperado) {
      throw RecusaDaApi(resposta.statusCode, _mensagemErro(resposta.body));
    }
    return EquipamentoModel.fromJson(
      jsonDecode(resposta.body) as Map<String, dynamic>,
    );
  }

  String _mensagemErro(String corpo) {
    try {
      final detalhe = jsonDecode(corpo)['detail'];

      if (detalhe is String) {
        return detalhe;
      }

      if (detalhe is List && detalhe.isNotEmpty) {
        final primeiro = detalhe.first;
        final mensagem = '${primeiro['msg']}'.replaceFirst('Value error, ', '');
        return '${primeiro['loc'].last}: $mensagem';
      }
    } catch (_) {
      // A API pode devolver uma resposta de erro que não seja JSON.
    }

    return 'Erro inesperado da API.';
  }
}

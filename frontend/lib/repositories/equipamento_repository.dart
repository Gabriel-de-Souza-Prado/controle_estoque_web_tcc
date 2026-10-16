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
      throw RecusaDaApi(
        resposta.statusCode,
        _mensagemErro(resposta.body),
      );
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
      throw RecusaDaApi(
        resposta.statusCode,
        _mensagemErro(resposta.body),
      );
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
        return '${primeiro['loc'].last}: ${primeiro['msg']}';
      }
    } catch (_) {
      // A API pode devolver uma resposta de erro que não seja JSON.
    }

    return 'Erro inesperado da API.';
  }
}
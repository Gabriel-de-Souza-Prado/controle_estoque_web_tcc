import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/usuario_model.dart';

class UsuarioRepository {
  UsuarioRepository({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  final http.Client _cliente;
  final String baseUrl = 'http://127.0.0.1:8000';

  // Faz POST /usuarios/login
  Future<String> login(String email, String senha) async {
    final response = await _cliente.post(
      Uri.parse('$baseUrl/usuarios/login'),
      body: {
        'username': email,
        'password': senha,
      },
    );

    if (response.statusCode == 200) {
      final dados = jsonDecode(response.body);
      return dados['access_token'];
    } else {
      throw Exception('E-mail ou senha incorretos.');
    }
  }

  // Faz GET /usuarios/eu passando o Bearer Token
  Future<UsuarioModel> obterUsuarioAtual(String token) async {
    final response = await _cliente.get(
      Uri.parse('$baseUrl/usuarios/eu'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return UsuarioModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Sessão expirada ou token inválido.');
    }
  }

  // Faz POST /usuarios para cadastrar novo técnico
  Future<void> cadastrar(String nome, String email, String senha) async {
    final response = await _cliente.post(
      Uri.parse('$baseUrl/usuarios'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'senha': senha,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      final erro = jsonDecode(response.body);
      throw Exception(erro['detail'] ?? 'Erro ao cadastrar usuário.');
    }
  }
}
import 'package:flutter/foundation.dart';
import '../models/usuario_model.dart';
import '../repositories/usuario_repository.dart';

class AuthService extends ChangeNotifier {
  final UsuarioRepository _repository;
  String? _token;
  UsuarioModel? _usuarioAtual;

  AuthService(this._repository);

  String? get token => _token;
  UsuarioModel? get usuarioAtual => _usuarioAtual;
  bool get logado => _token != null && _usuarioAtual != null;

  Future<void> realizarLogin(String email, String senha) async {
    _token = await _repository.login(email, senha);
  }

  Future<UsuarioModel> carregarPerfil() async {
    if (_token == null) {
      throw Exception('Usuário não autenticado.');
    }
    _usuarioAtual = await _repository.obterUsuarioAtual(_token!);
    notifyListeners();
    return _usuarioAtual!;
  }

  // Faz os dois passos juntos; se o perfil falhar, não deixa token pela metade.
  Future<void> entrar(String email, String senha) async {
    if (email.isEmpty || senha.isEmpty) {
      throw Exception('Preencha o e-mail e a senha.');
    }
    await realizarLogin(email, senha);
    try {
      await carregarPerfil();
    } catch (e) {
      _token = null;
      _usuarioAtual = null;
      rethrow;
    }
  }

  void logout() {
    _token = null;
    _usuarioAtual = null;
    notifyListeners();
  }

  Future<void> cadastrarUsuario(String nome, String email, String senha) async {
    await _repository.cadastrar(nome, email, senha);
  }
}
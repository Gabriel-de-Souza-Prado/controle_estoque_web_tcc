import '../models/equipamento_model.dart';
import '../repositories/equipamento_repository.dart';
import '../repositories/usuario_repository.dart';
import 'auth_service.dart';

class ErroDeEquipamentos implements Exception {
  ErroDeEquipamentos(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

/// A tela pede operações; o serviço obtém a sessão e traduz as falhas.
/// HTTP e JSON ficam no repositório. O estado visual fica nas telas.
class EquipamentoService {
  EquipamentoService(this.repositorio, this.auth);

  final EquipamentoRepository repositorio;
  final AuthService auth;

  Future<List<EquipamentoModel>> listar() =>
      _comSessao((token) => repositorio.listar(token));

  Future<EquipamentoModel> buscar(int id) =>
      _comSessao((token) => repositorio.buscar(token, id));

  Future<EquipamentoModel> criar(DadosEquipamento dados) =>
      _comSessao((token) => repositorio.criar(token, dados));

  Future<EquipamentoModel> atualizar(int id, DadosEquipamento dados) =>
      _comSessao((token) => repositorio.atualizar(token, id, dados));

  Future<void> excluir(int id) =>
      _comSessao((token) => repositorio.excluir(token, id));

  Future<T> _comSessao<T>(Future<T> Function(String token) operacao) async {
    final token = auth.token;
    if (token == null) {
      throw ErroDeEquipamentos('Entre novamente para acessar os equipamentos.');
    }
    try {
      return await operacao(token);
    } on RecusaDaApi catch (e) {
      throw ErroDeEquipamentos(e.mensagem);
    } on Exception {
      throw ErroDeEquipamentos(
        'Não consegui falar com a API. O servidor está rodando?',
      );
    }
  }
}

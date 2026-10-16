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

/// Obtém o token da sessão e traduz falhas da API para mensagens de interface.
class EquipamentoService {
  EquipamentoService(this.repositorio, this.auth);

  final EquipamentoRepository repositorio;
  final AuthService auth;

  Future<List<EquipamentoModel>> listar() async {
    try {
      final token = auth.token;

      if (token == null) {
        throw ErroDeEquipamentos(
          'Entre novamente para acessar os equipamentos.',
        );
      }

      return await repositorio.listar(token);
    } on RecusaDaApi catch (e) {
      throw ErroDeEquipamentos(e.mensagem);
    } on ErroDeEquipamentos {
      rethrow;
    } on Exception {
      throw ErroDeEquipamentos(
        'Não consegui falar com a API. O uvicorn está rodando?',
      );
    }
  }

  Future<EquipamentoModel> buscar(int id) async {
    try {
      final token = auth.token;

      if (token == null) {
        throw ErroDeEquipamentos(
          'Entre novamente para acessar os equipamentos.',
        );
      }

      return await repositorio.buscar(token, id);
    } on RecusaDaApi catch (e) {
      throw ErroDeEquipamentos(e.mensagem);
    } on ErroDeEquipamentos {
      rethrow;
    } on Exception {
      throw ErroDeEquipamentos(
        'Não consegui falar com a API. O uvicorn está rodando?',
      );
    }
  }
}
/// Representa um equipamento devolvido pela API (`EquipamentoPublico`).
class EquipamentoModel {
  const EquipamentoModel({
    required this.id,
    required this.dti,
    required this.modelo,
    required this.numeroSerie,
    required this.categoria,
    required this.status,
    required this.departamento,
    this.observacao,
    this.donoId,
  });

  final int id;
  final String dti;
  final String modelo;
  final String numeroSerie;
  final String categoria;
  final String status;
  final String departamento;
  final String? observacao;
  final int? donoId;

  factory EquipamentoModel.fromJson(Map<String, dynamic> json) {
    return EquipamentoModel(
      id: json['id'] as int,
      dti: json['dti'] as String,
      modelo: json['modelo'] as String,
      numeroSerie: json['numero_serie'] as String,
      categoria: json['categoria'] as String,
      status: json['status'] as String,
      departamento: json['departamento'] as String,
      observacao: json['observacao'] as String?,
      donoId: json['dono_id'] as int?,
    );
  }
}

/// Dados do formulário, sem id nem dono: esses valores pertencem à API.
class DadosEquipamento {
  const DadosEquipamento({
    required this.dti,
    required this.modelo,
    required this.numeroSerie,
    required this.categoria,
    required this.status,
    required this.departamento,
    this.observacao,
  });

  final String dti;
  final String modelo;
  final String numeroSerie;
  final String categoria;
  final String status;
  final String departamento;
  final String? observacao;
}

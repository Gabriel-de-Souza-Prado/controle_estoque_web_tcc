class UsuarioModel {
  final int id;
  final String nome;
  final String email;

  UsuarioModel({
    required this.id,
    required this.nome,
    required this.email,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
    );
  }
}
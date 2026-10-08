import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';

class RotaProtegida extends StatelessWidget {
  const RotaProtegida({super.key, required this.tela});
  final Widget tela;

  @override
  Widget build(BuildContext context) {
    final logado = context.watch<AuthService>().logado;
    return logado ? tela : const LoginScreen();
  }
}
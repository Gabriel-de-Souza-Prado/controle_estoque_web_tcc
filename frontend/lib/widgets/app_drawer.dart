import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../routes.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthService>().usuarioAtual!;
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(usuario.nome),
            accountEmail: Text(usuario.email),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Início'),
            onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.inicio),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Produtos'),
            onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.produtos),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Movimentações'),
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.movimentacoes),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil'),
            onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.perfil),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () {
              context.read<AuthService>().logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (rota) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
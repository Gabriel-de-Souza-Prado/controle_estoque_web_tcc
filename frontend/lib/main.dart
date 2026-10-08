import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'repositories/usuario_repository.dart';
import 'routes.dart';
import 'screens/cadastro_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/movimentacoes_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/produtos_screen.dart';
import 'services/auth_service.dart';
import 'widgets/rota_protegida.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService(UsuarioRepository()),
      child: const MeuAppEstoque(),
    ),
  );
}

class MeuAppEstoque extends StatelessWidget {
  const MeuAppEstoque({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Estoque TI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: false),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.cadastro: (context) => const CadastroScreen(),
        AppRoutes.inicio: (context) => const RotaProtegida(tela: HomeScreen()),
        AppRoutes.produtos: (context) => const RotaProtegida(tela: ProdutosScreen()),
        AppRoutes.movimentacoes: (context) =>
            const RotaProtegida(tela: MovimentacoesScreen()),
        AppRoutes.perfil: (context) => const RotaProtegida(tela: PerfilScreen()),
      },
    );
  }
}
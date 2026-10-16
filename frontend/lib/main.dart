import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'repositories/token_repository.dart';
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

// Aqui as camadas se montam, como o main.py monta a API no backend: os
// repositórios entram no service, e o service fica no topo do app, onde toda
// tela o alcança, sem passar de construtor em construtor.
Future<void> main() async {
  // O Flutter precisa estar de pé antes de qualquer pacote falar com o aparelho.
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthService(UsuarioRepository(), tokens: TokenRepository());
  // Antes de a primeira tela aparecer: se o aparelho guardou um token que a
  // API ainda aceita, a sessão volta e o app abre logado.
  await auth.restaurar();
  runApp(
    ChangeNotifierProvider.value(value: auth, child: const MeuAppEstoque()),
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
      // A rota inicial é a tela inicial: sem sessão, o guarda (RotaProtegida)
      // mostra o login no lugar; com sessão restaurada, ela abre direto.
      initialRoute: AppRoutes.inicio,
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
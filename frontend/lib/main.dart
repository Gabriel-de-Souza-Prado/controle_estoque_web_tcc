import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/equipamento_model.dart';
import 'repositories/equipamento_repository.dart';
import 'repositories/token_repository.dart';
import 'repositories/usuario_repository.dart';
import 'routes.dart';
import 'screens/cadastro_screen.dart';
import 'screens/equipamento_screen.dart';
import 'screens/formulario_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/movimentacoes_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/produtos_screen.dart';
import 'services/auth_service.dart';
import 'services/equipamento_service.dart';
import 'widgets/rota_protegida.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final auth = AuthService(UsuarioRepository(), tokens: TokenRepository());

  await auth.restaurar();

  runApp(
    ChangeNotifierProvider.value(value: auth, child: const MeuAppEstoque()),
  );
}

class MeuAppEstoque extends StatelessWidget {
  const MeuAppEstoque({super.key, this.equipamentoRepository});

  // Permite injetar uma API simulada nos testes automatizados.
  final EquipamentoRepository? equipamentoRepository;

  @override
  Widget build(BuildContext context) {
    return Provider<EquipamentoService>(
      create: (context) => EquipamentoService(
        equipamentoRepository ?? EquipamentoRepository(),
        context.read<AuthService>(),
      ),
      child: MaterialApp(
        title: 'Estoque TI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: false),
        initialRoute: AppRoutes.inicio,
        routes: {
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.cadastro: (context) => const CadastroScreen(),
          AppRoutes.inicio: (context) =>
              const RotaProtegida(tela: HomeScreen()),
          AppRoutes.produtos: (context) =>
              const RotaProtegida(tela: ProdutosScreen()),
          AppRoutes.equipamento: (context) {
            final argumento = ModalRoute.of(context)?.settings.arguments;

            return RotaProtegida(
              tela: EquipamentoScreen(id: argumento is int ? argumento : null),
            );
          },
          AppRoutes.movimentacoes: (context) =>
              const RotaProtegida(tela: MovimentacoesScreen()),
          AppRoutes.formulario: (context) {
            final argumento = ModalRoute.of(context)?.settings.arguments;
            return RotaProtegida(
              tela: FormularioScreen(
                equipamento: argumento is EquipamentoModel ? argumento : null,
              ),
            );
          },
          AppRoutes.perfil: (context) =>
              const RotaProtegida(tela: PerfilScreen()),
        },
      ),
    );
  }
}

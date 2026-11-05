import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/equipamento_model.dart';
import '../routes.dart';
import '../services/equipamento_service.dart';
import '../widgets/app_drawer.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  late Future<List<EquipamentoModel>> pedido;
  final campoBusca = TextEditingController();
  String busca = '';
  bool soNoEstoque = false;

  @override
  void initState() {
    super.initState();

    // O pedido nasce uma única vez, não a cada reconstrução da tela.
    final servico = context.read<EquipamentoService>();
    pedido = Future<List<EquipamentoModel>>.microtask(servico.listar);
  }

  void tentarDeNovo() {
    setState(() {
      pedido = context.read<EquipamentoService>().listar(
        busca: busca,
        soNoEstoque: soNoEstoque,
      );
      // A recusa pode chegar antes do próximo build (por exemplo, em cache
      // ou nos testes). O FutureBuilder continua mostrando o erro na tela.
      pedido.ignore();
    });
  }

  void buscar(String texto) {
    busca = texto.trim();
    tentarDeNovo();
  }

  void limparBusca() {
    campoBusca.clear();
    buscar('');
  }

  @override
  void dispose() {
    campoBusca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipamentos')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: campoBusca,
              decoration: InputDecoration(
                labelText: 'Buscar pelo DTI',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Limpar busca',
                  icon: const Icon(Icons.clear),
                  onPressed: limparBusca,
                ),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: buscar,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Só no estoque'),
                selected: soNoEstoque,
                onSelected: (valor) {
                  soNoEstoque = valor;
                  tentarDeNovo();
                },
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<EquipamentoModel>>(
              future: pedido,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _EstadoComErro(
                    titulo: 'Não consegui carregar os equipamentos',
                    erro: '${snapshot.error}',
                    tentarDeNovo: tentarDeNovo,
                  );
                }

                final equipamentos =
                    snapshot.data ?? const <EquipamentoModel>[];

                if (equipamentos.isEmpty) {
                  final frase = busca.isEmpty
                      ? (soNoEstoque
                            ? 'Nenhum equipamento no estoque.'
                            : 'Nenhum equipamento cadastrado.')
                      : (soNoEstoque
                            ? 'Nenhum equipamento no estoque com "$busca" no DTI.'
                            : 'Nenhum equipamento com "$busca" no DTI.');
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 56),
                          const SizedBox(height: 16),
                          Text(frase, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: equipamentos.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final equipamento = equipamentos[index];

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.devices)),
                      title: Text(equipamento.modelo),
                      subtitle: Text(
                        'DTI: ${equipamento.dti} • '
                        '${equipamento.departamento}\n'
                        '${equipamento.categoria} • '
                        '${equipamento.status}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final mudou = await Navigator.pushNamed(
                          context,
                          AppRoutes.equipamento,
                          arguments: equipamento.id,
                        );
                        if (mudou == true && mounted) tentarDeNovo();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo equipamento',
        onPressed: () async {
          final salvou = await Navigator.pushNamed(
            context,
            AppRoutes.formulario,
          );
          if (salvou == true && mounted) tentarDeNovo();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EstadoComErro extends StatelessWidget {
  const _EstadoComErro({
    required this.titulo,
    required this.erro,
    required this.tentarDeNovo,
  });

  final String titulo;
  final String erro;
  final VoidCallback tentarDeNovo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56),
            const SizedBox(height: 16),
            Text(titulo, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              erro,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: tentarDeNovo,
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}

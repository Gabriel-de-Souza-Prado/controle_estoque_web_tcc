import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/equipamento_model.dart';
import '../routes.dart';
import '../services/equipamento_service.dart';
import 'produtos_screen.dart';

class EquipamentoScreen extends StatefulWidget {
  const EquipamentoScreen({super.key, this.id});

  final int? id;

  @override
  State<EquipamentoScreen> createState() => _EquipamentoScreenState();
}

class _EquipamentoScreenState extends State<EquipamentoScreen> {
  late Future<EquipamentoModel> pedido;
  bool excluindo = false;
  String? erro;

  Future<void> editar(EquipamentoModel equipamento) async {
    final salvou = await Navigator.pushNamed(
      context,
      AppRoutes.formulario,
      arguments: equipamento,
    );
    if (salvou == true && mounted) Navigator.pop(context, true);
  }

  Future<void> excluir(EquipamentoModel equipamento) async {
    if (excluindo) return;
    final certeza = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir ${equipamento.modelo} (DTI ${equipamento.dti})?'),
        content: const Text(
          'O equipamento será removido do estoque. Não é possível desfazer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (certeza != true || !mounted) return;
    setState(() {
      excluindo = true;
      erro = null;
    });
    try {
      await context.read<EquipamentoService>().excluir(equipamento.id);
    } on ErroDeEquipamentos catch (e) {
      if (!mounted) return;
      setState(() {
        excluindo = false;
        erro = e.mensagem;
      });
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void initState() {
    super.initState();

    if (widget.id != null) {
      final servico = context.read<EquipamentoService>();
      pedido = Future<EquipamentoModel>.microtask(
        () => servico.buscar(widget.id!),
      );
    }
  }

  void tentarDeNovo() {
    setState(() {
      pedido = context.read<EquipamentoService>().buscar(widget.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.id == null) {
      return const ProdutosScreen();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do equipamento')),
      body: FutureBuilder<EquipamentoModel>(
        future: pedido,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 56),
                    const SizedBox(height: 16),
                    const Text('Não consegui carregar o equipamento'),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
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

          final equipamento = snapshot.data!;

          return ListView(
            children: [
              _CampoEquipamento(
                rotulo: 'DTI',
                valor: equipamento.dti,
                icone: Icons.qr_code,
              ),
              _CampoEquipamento(
                rotulo: 'Modelo',
                valor: equipamento.modelo,
                icone: Icons.devices,
              ),
              _CampoEquipamento(
                rotulo: 'Número de série',
                valor: equipamento.numeroSerie,
                icone: Icons.tag,
              ),
              _CampoEquipamento(
                rotulo: 'Categoria',
                valor: equipamento.categoria,
                icone: Icons.category,
              ),
              _CampoEquipamento(
                rotulo: 'Status',
                valor: equipamento.status,
                icone: Icons.info_outline,
              ),
              _CampoEquipamento(
                rotulo: 'Departamento',
                valor: equipamento.departamento,
                icone: Icons.apartment,
              ),
              _CampoEquipamento(
                rotulo: 'Observação',
                valor: equipamento.observacao?.trim().isNotEmpty == true
                    ? equipamento.observacao!
                    : 'Nenhuma observação',
                icone: Icons.notes,
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: excluindo ? null : () => editar(equipamento),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: excluindo ? null : () => excluir(equipamento),
                    icon: const Icon(Icons.delete),
                    label: Text(excluindo ? 'Excluindo...' : 'Excluir'),
                  ),
                ],
              ),
              if (erro != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    erro!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CampoEquipamento extends StatelessWidget {
  const _CampoEquipamento({
    required this.rotulo,
    required this.valor,
    required this.icone,
  });

  final String rotulo;
  final String valor;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icone),
      title: Text(rotulo),
      subtitle: Text(valor),
    );
  }
}

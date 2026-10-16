import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/equipamento_model.dart';
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

  @override
  void initState() {
    super.initState();

    if (widget.id != null) {
      pedido = Future<EquipamentoModel>.microtask(
        () => context.read<EquipamentoService>().buscar(widget.id!),
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
      appBar: AppBar(
        title: const Text('Detalhes do equipamento'),
      ),
      body: FutureBuilder<EquipamentoModel>(
        future: pedido,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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
                    const Text(
                      'Não consegui carregar o equipamento',
                    ),
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
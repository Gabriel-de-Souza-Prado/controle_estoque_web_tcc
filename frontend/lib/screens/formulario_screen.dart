import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/equipamento_model.dart';
import '../services/equipamento_service.dart';
import 'produtos_screen.dart';

/// Sem equipamento, cria. Com equipamento, edita os mesmos campos.
class FormularioScreen extends StatefulWidget {
  const FormularioScreen({super.key, this.equipamento});

  final EquipamentoModel? equipamento;

  @override
  State<FormularioScreen> createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final chave = GlobalKey<FormState>();
  final dti = TextEditingController();
  final modelo = TextEditingController();
  final numeroSerie = TextEditingController();
  final categoria = TextEditingController();
  final departamento = TextEditingController();
  final observacao = TextEditingController();
  String status = 'No Estoque';
  bool salvando = false;
  String? erro;

  static const statusPermitidos = [
    'Em Uso',
    'No Estoque',
    'Em Manutenção',
    'Descartado',
  ];

  @override
  void initState() {
    super.initState();
    final equipamento = widget.equipamento;
    if (equipamento != null) {
      dti.text = equipamento.dti;
      modelo.text = equipamento.modelo;
      numeroSerie.text = equipamento.numeroSerie;
      categoria.text = equipamento.categoria;
      departamento.text = equipamento.departamento;
      observacao.text = equipamento.observacao ?? '';
      status = equipamento.status;
    }
  }

  Future<void> salvar() async {
    if (salvando || !chave.currentState!.validate()) return;
    setState(() {
      salvando = true;
      erro = null;
    });

    final dados = DadosEquipamento(
      dti: dti.text.trim(),
      modelo: modelo.text.trim(),
      numeroSerie: numeroSerie.text.trim(),
      categoria: categoria.text.trim(),
      status: status,
      departamento: departamento.text.trim(),
      observacao: observacao.text.trim().isEmpty
          ? null
          : observacao.text.trim(),
    );
    final servico = context.read<EquipamentoService>();
    try {
      final equipamento = widget.equipamento;
      if (equipamento == null) {
        await servico.criar(dados);
      } else {
        await servico.atualizar(equipamento.id, dados);
      }
    } on ErroDeEquipamentos catch (e) {
      if (!mounted) return;
      setState(() {
        salvando = false;
        erro = e.mensagem;
      });
      return;
    }
    if (!mounted) return;
    // Quem abriu esta tela recebe true e busca os dados atuais na API.
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    dti.dispose();
    modelo.dispose();
    numeroSerie.dispose();
    categoria.dispose();
    departamento.dispose();
    observacao.dispose();
    super.dispose();
  }

  Widget campo(
    String rotulo,
    TextEditingController controller, {
    int minimo = 2,
    required int maximo,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !salvando,
      decoration: InputDecoration(
        labelText: rotulo,
        border: const OutlineInputBorder(),
      ),
      validator: (valor) {
        final texto = (valor ?? '').trim();
        if (texto.isEmpty) return 'Informe $rotulo';
        if (texto.length < minimo) {
          return '$rotulo precisa ter pelo menos $minimo caracteres';
        }
        if (texto.length > maximo) {
          return '$rotulo pode ter no máximo $maximo caracteres';
        }
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Ao recarregar a URL, não existe uma tela esperando o resultado.
    if (ModalRoute.of(context)?.isFirst == true) {
      return const ProdutosScreen();
    }
    return PopScope(
      canPop: !salvando,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.equipamento == null
                ? 'Novo equipamento'
                : 'Editar equipamento',
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: chave,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    campo('DTI', dti, minimo: 3, maximo: 50),
                    campo('Modelo', modelo, maximo: 120),
                    campo('Número de série', numeroSerie, maximo: 120),
                    campo('Categoria', categoria, maximo: 50),
                    campo('Departamento', departamento, minimo: 3, maximo: 100),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        // Permite corrigir um status antigo fora das opções.
                        for (final opcao in {...statusPermitidos, status})
                          DropdownMenuItem(value: opcao, child: Text(opcao)),
                      ],
                      onChanged: salvando
                          ? null
                          : (valor) {
                              if (valor != null) setState(() => status = valor);
                            },
                      validator: (valor) => statusPermitidos.contains(valor)
                          ? null
                          : 'Selecione um status válido',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: observacao,
                      enabled: !salvando,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Observação',
                        helperText: status == 'Em Manutenção'
                            ? 'Obrigatória para equipamentos em manutenção'
                            : 'Opcional',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        final texto = (valor ?? '').trim();
                        if (status == 'Em Manutenção' && texto.isEmpty) {
                          return 'Informe a observação para manutenção';
                        }
                        if (texto.length > 255) {
                          return 'Observação pode ter no máximo 255 caracteres';
                        }
                        return null;
                      },
                    ),
                    if (erro != null) ...[
                      const SizedBox(height: 16),
                      Text(erro!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: salvando ? null : salvar,
                      child: Text(salvando ? 'Salvando...' : 'Salvar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class MovimentacoesScreen extends StatelessWidget {
  const MovimentacoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movimentações')),
      drawer: const AppDrawer(),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz, size: 56),
            SizedBox(height: 16),
            Text('A tela de movimentações chega adiante.'),
          ],
        ),
      ),
    );
  }
}
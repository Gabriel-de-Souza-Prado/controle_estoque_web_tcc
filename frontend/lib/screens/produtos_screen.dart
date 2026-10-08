import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class ProdutosScreen extends StatelessWidget {
  const ProdutosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produtos')),
      drawer: const AppDrawer(),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2, size: 56),
            SizedBox(height: 16),
            Text('A listagem dos produtos chega adiante.'),
          ],
        ),
      ),
    );
  }
}
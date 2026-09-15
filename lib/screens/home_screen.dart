import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ordens de serviço')),
      body: const Center(
        child: Text('Bem-vindo ao sistema de ordens de serviço.'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/imovel_detalhe.dart';

class PerfilCorretorScreen extends StatelessWidget {
  final CorretorResumo corretor;

  const PerfilCorretorScreen({
    super.key,
    required this.corretor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do corretor')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.network(
                corretor.fotoUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox(
                  width: 120,
                  height: 120,
                  child: Icon(Icons.person, size: 72),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              corretor.nome,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('CRECI: ${corretor.creci}'),
          ],
        ),
      ),
    );
  }
}
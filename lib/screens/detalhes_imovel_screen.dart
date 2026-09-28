import 'package:flutter/material.dart';
import '../models/imovel.dart';

class DetalhesImovelScreen extends StatelessWidget {
  const DetalhesImovelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Recupera o objeto enviado via arguments na rota
    final imovel = ModalRoute.of(context)?.settings.arguments as Imovel?;

    if (imovel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: const Center(child: Text('Imóvel não encontrado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(imovel.titulo),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do imóvel
            Image.network(
              imovel.imagemUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.home, size: 80, color: Colors.grey),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'R\$ ${imovel.preco.toStringAsFixed(2)} / mês',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.king_bed, size: 18),
                        label: Text('${imovel.quartos} quartos'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        imovel.cidade,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Descrição',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Excelente imóvel bem localizado, próximo a comércios, transportes e vias de acesso principal. Ideal para quem busca conforto e praticidade.',
                    style: TextStyle(fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Ação futura: Entrar em contato com o anunciante
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Iniciando contato com o proprietário...')),
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Tenho Interesse'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
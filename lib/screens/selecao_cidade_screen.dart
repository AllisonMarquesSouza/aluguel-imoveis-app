import 'package:flutter/material.dart';
import '../services/imovel_service.dart';

class SelecaoCidadeScreen extends StatefulWidget {
  const SelecaoCidadeScreen({super.key});

  @override
  State<SelecaoCidadeScreen> createState() => _SelecaoCidadeScreenState();
}

class _SelecaoCidadeScreenState extends State<SelecaoCidadeScreen> {
  final ImovelService _service = ImovelServiceMock(); // Mock centralizado

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecione uma Cidade')),
      body: FutureBuilder<List<String>>(
        future: _service.getCidadesAtendidas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final cidades = snapshot.data ?? [];

          return ListView.builder(
            itemCount: cidades.length,
            itemBuilder: (context, index) {
              final cidade = cidades[index];
              return ListTile(
                title: Text(cidade),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Retorna a cidade escolhida para a tela anterior
                  Navigator.pop(context, cidade);
                },
              );
            },
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/imovel_service.dart';

class SelecaoCidadeScreen extends StatefulWidget {
  const SelecaoCidadeScreen({super.key});

  @override
  State<SelecaoCidadeScreen> createState() => _SelecaoCidadeScreenState();
}

class _SelecaoCidadeScreenState extends State<SelecaoCidadeScreen> {
  final ImovelService _service = ImovelServiceApi();
  late Future<List<String>> _cidadesFuture;

  @override
  void initState() {
    super.initState();
    _cidadesFuture = _service.getCidadesAtendidas();
  }

  void _tentarNovamente() {
    setState(() => _cidadesFuture = _service.getCidadesAtendidas());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecione uma Cidade')),
      body: FutureBuilder<List<String>>(
        future: _cidadesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(snapshot.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _tentarNovamente, child: const Text('Tentar novamente')),
                  ],
                ),
              ),
            );
          }

          final cidades = snapshot.data ?? [];
          if (cidades.isEmpty) {
            return const Center(child: Text('A API não retornou cidades disponíveis.'));
          }

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

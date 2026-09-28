import 'package:flutter/material.dart';
import '../models/imovel.dart';
import '../services/imovel_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImovelService _service = ImovelServiceMock();
  String cidadeSelecionada = 'São Paulo'; // Valor inicial guardado/padrão

  @override
  void initState() {
    super.initState();
    _verificarPermissaoEObterCidade();
  }

  void _verificarPermissaoEObterCidade() async {
    // Simulação do diálogo de permissão de localização
    // Em produção, usaremos a biblioteca 'geolocator' ou 'permission_handler'
    Future.microtask(() {
      _mostrarDialogoPermissao();
    });
  }

  void _mostrarDialogoPermissao() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissão de Localização'),
        content: const Text(
          'Precisamos da sua localização para mostrar automaticamente os imóveis disponíveis na sua cidade atual.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Recusou permissão
              // Abre a lista de cidades para escolha manual
              final cidadeEscolhida = await Navigator.pushNamed(context, '/selecionar-cidade');
              if (cidadeEscolhida != null && cidadeEscolhida is String) {
                setState(() {
                  cidadeSelecionada = cidadeEscolhida;
                });
              }
            },
            child: const Text('Recusar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Aceitou permissão
              setState(() {
                cidadeSelecionada = 'São Paulo'; // Cidade detectada pelo GPS (mock)
              });
            },
            child: const Text('Permitir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () async {
            // Permitir trocar cidade no topo da tela
            final novaCidade = await Navigator.pushNamed(context, '/selecionar-cidade');
            if (novaCidade != null && novaCidade is String) {
              setState(() {
                cidadeSelecionada = novaCidade;
              });
            }
          },
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 20),
              const SizedBox(width: 6),
              Text(cidadeSelecionada),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<Imovel>>(
        future: _service.getImoveisPorCidade(cidadeSelecionada),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final imoveis = snapshot.data ?? [];

          if (imoveis.isEmpty) {
            return const Center(child: Text('Nenhum imóvel encontrado para esta cidade.'));
          }

          return ListView.builder(
            itemCount: imoveis.length,
            itemBuilder: (context, index) {
              final imovel = imoveis[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(imovel.titulo),
                  subtitle: Text('R\$ ${imovel.preco} - ${imovel.quartos} quartos'),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/detalhes-imovel',
                      arguments: imovel,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/imovel_detalhe.dart';
import '../services/imovel_detalhe_service.dart';

class DetalhesImovelScreen extends StatefulWidget {
  final String imovelId;

  const DetalhesImovelScreen({super.key, required this.imovelId});

  @override
  State<DetalhesImovelScreen> createState() => _DetalhesImovelScreenState();
}

class _DetalhesImovelScreenState extends State<DetalhesImovelScreen> {
  final ImovelDetalheService _service = ImovelDetalheService();
  late Future<ImovelDetalhe> _imovelFuture;

  @override
  void initState() {
    super.initState();
    _imovelFuture = _service.buscarPorId(widget.imovelId);
  }

  void _tentarNovamente() {
    setState(() {
      _imovelFuture = _service.buscarPorId(widget.imovelId);
    });
  }

  String _formatarMoeda(double valor) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor);
  }

  Widget _secaoDetalhesNatureza(ImovelDetalhe imovel) {
    final detalhes = imovel.detalhes;

    late final String titulo;
    late final List<MapEntry<String, String>> campos;

    switch (imovel.natureza) {
      case NaturezaImovel.casa:
        titulo = 'Detalhes da casa';
        campos = const [
          MapEntry('areaTerrenoM2', 'Área do terreno (m²)'),
          MapEntry('areaConstruidaM2', 'Área construída (m²)'),
          MapEntry('areaLivreM2', 'Área livre (m²)'),
        ];
        break;
      case NaturezaImovel.apartamento:
        titulo = 'Dados do prédio';
        campos = const [
          MapEntry('nomePredio', 'Prédio'),
          MapEntry('andar', 'Andar'),
          MapEntry('totalAndares', 'Andares no prédio'),
          MapEntry('vagas', 'Vagas'),
        ];
        break;
      case NaturezaImovel.terreno:
        titulo = 'Detalhes do terreno';
        campos = const [
          MapEntry('frenteM', 'Frente (m)'),
          MapEntry('fundoM', 'Fundo (m)'),
          MapEntry('topografia', 'Topografia'),
        ];
        break;
      case NaturezaImovel.lote:
        titulo = 'Detalhes do lote';
        campos = const [
          MapEntry('loteamento', 'Loteamento'),
          MapEntry('quadra', 'Quadra'),
          MapEntry('numeroLote', 'Lote'),
          MapEntry('areaM2', 'Área (m²)'),
        ];
        break;
    }

    final camposDisponiveis = campos
        .where((campo) => detalhes[campo.key] != null)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(titulo, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (camposDisponiveis.isEmpty)
          const Text('Detalhes específicos não informados pela API.')
        else
          ...camposDisponiveis.map(
            (campo) => Text('${campo.value}: ${detalhes[campo.key]}'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImovelDetalhe>(
      future: _imovelFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalhe do imóvel')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalhe do imóvel')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Não foi possível carregar este imóvel.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _tentarNovamente,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final imovel = snapshot.data;

        if (imovel == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalhe do imóvel')),
            body: const Center(child: Text('Imóvel não encontrado.')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(imovel.titulo)),
          body: ListView(
            children: [
              GaleriaImovel(fotos: imovel.fotos),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      imovel.titulo,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${imovel.localizacao.bairro}, '
                      '${imovel.localizacao.cidade} - '
                      '${imovel.localizacao.uf}',
                    ),
                    const SizedBox(height: 16),
                    Text(imovel.descricao),
                    _secaoDetalhesNatureza(imovel),
                    const SizedBox(height: 16),
                    Text(
                      'Valores',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (imovel.venda != null)
                      Text('Venda: ${_formatarMoeda(imovel.venda!.valor)}'),
                    if (imovel.aluguelMensal != null)
                      Text(
                        'Aluguel: ${_formatarMoeda(imovel.aluguelMensal!)} por mês',
                      ),
                    if (imovel.condominioMensal != null)
                      Text(
                        'Condomínio: ${_formatarMoeda(imovel.condominioMensal!)} por mês',
                      ),
                    if (imovel.iptuAnual != null)
                      Text(
                        'IPTU: ${_formatarMoeda(imovel.iptuAnual!)} por ano',
                      ),
                    const SizedBox(height: 24),
                    ListTile(
                      leading: CircleAvatar(
                        child: ClipOval(
                          child: Image.network(
                            imovel.corretor.fotoUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person),
                          ),
                        ),
                      ),
                      title: Text(imovel.corretor.nome),
                      subtitle: Text('CRECI: ${imovel.corretor.creci}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/perfil-corretor',
                          arguments: imovel.corretor,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class GaleriaImovel extends StatefulWidget {
  final List<FotoImovel> fotos;

  const GaleriaImovel({super.key, required this.fotos});

  @override
  State<GaleriaImovel> createState() => _GaleriaImovelState();
}

class _GaleriaImovelState extends State<GaleriaImovel> {
  int _paginaAtual = 0;

  List<FotoImovel> get _fotosOrdenadas {
    final fotos = List<FotoImovel>.from(widget.fotos);

    fotos.sort((a, b) {
      if (a.capa != b.capa) {
        return a.capa ? -1 : 1;
      }
      return a.ordem.compareTo(b.ordem);
    });

    return fotos;
  }

  @override
  Widget build(BuildContext context) {
    final fotos = _fotosOrdenadas;

    if (fotos.isEmpty) {
      return Container(
        height: 260,
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.home, size: 64),
      );
    }

    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: fotos.length,
            onPageChanged: (pagina) {
              setState(() {
                _paginaAtual = pagina;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                fotos[index].url,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, size: 48),
                  );
                },
              );
            },
          ),
          if (fotos.length > 1)
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_paginaAtual + 1} de ${fotos.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/imovel_detalhe.dart';
import '../models/imovel.dart';
import '../services/imovel_detalhe_service.dart';
import '../services/favoritos_service.dart';

class DetalhesImovelScreen extends StatefulWidget {
  final String imovelId;
  final Imovel imovelResumo;
  final FavoritosService favoritosService;

  const DetalhesImovelScreen({
    super.key,
    required this.imovelId,
    required this.imovelResumo,
    required this.favoritosService,
  });

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

  Future<void> _abrirRota(double latitude, double longitude) async {
    final uri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {
        'api': '1',
        'destination': '$latitude,$longitude',
      },
    );

    final abriu = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o aplicativo de mapas.'),
        ),
      );
    }
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
          appBar: AppBar(
            title: Text(imovel.titulo),
            actions: [
              ValueListenableBuilder<List<Imovel>>(
                valueListenable: widget.favoritosService.favoritos,
                builder: (context, favoritos, _) {
                  final isFavorito = favoritos.any(
                    (favorito) => favorito.id == widget.imovelResumo.id,
                  );

                  return IconButton(
                    tooltip: isFavorito
                        ? 'Remover dos favoritos'
                        : 'Adicionar aos favoritos',
                    onPressed: () {
                      widget.favoritosService.alternar(widget.imovelResumo);
                    },
                    icon: Icon(
                      isFavorito ? Icons.favorite : Icons.favorite_border,
                      color: isFavorito ? Colors.red : null,
                    ),
                  );
                },
              ),
            ],
          ),
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
                    if (imovel.localizacao.latitude == null ||
                        imovel.localizacao.longitude == null)
                      const Text(
                        'A localização no mapa não está disponível para este imóvel.',
                      )
                    else
                      SizedBox(
                        height: 240,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                imovel.localizacao.latitude!,
                                imovel.localizacao.longitude!,
                              ),
                              initialZoom: 15,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.example.aluguel_imoveis_app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      imovel.localizacao.latitude!,
                                      imovel.localizacao.longitude!,
                                    ),
                                    width: 44,
                                    height: 44,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 42,
                                    ),
                                  ),
                                ],
                              ),
                              RichAttributionWidget(
                                attributions: [
                                  TextSourceAttribution(
                                    '© OpenStreetMap contributors',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (imovel.localizacao.latitude != null &&
                        imovel.localizacao.longitude != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _abrirRota(
                              imovel.localizacao.latitude!,
                              imovel.localizacao.longitude!,
                            );
                          },
                          icon: const Icon(Icons.directions),
                          label: const Text('Abrir rota no app de mapas'),
                        ),
                      ),
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

  void _abrirImagemMaximizada(List<FotoImovel> fotos, int indiceInicial) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _GaleriaImagemMaximizada(
          fotos: fotos,
          indiceInicial: indiceInicial,
        ),
      ),
    );
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
              return GestureDetector(
                onTap: () => _abrirImagemMaximizada(fotos, index),
                child: Image.network(
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
                ),
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

class _GaleriaImagemMaximizada extends StatefulWidget {
  final List<FotoImovel> fotos;
  final int indiceInicial;

  const _GaleriaImagemMaximizada({
    required this.fotos,
    required this.indiceInicial,
  });

  @override
  State<_GaleriaImagemMaximizada> createState() =>
      _GaleriaImagemMaximizadaState();
}

class _GaleriaImagemMaximizadaState extends State<_GaleriaImagemMaximizada> {
  late final PageController _pageController;
  late int _paginaAtual;

  @override
  void initState() {
    super.initState();
    _paginaAtual = widget.indiceInicial;
    _pageController = PageController(initialPage: widget.indiceInicial);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.fotos.length,
              onPageChanged: (pagina) {
                setState(() {
                  _paginaAtual = pagina;
                });
              },
              itemBuilder: (context, index) {
                return Center(
                  child: Image.network(
                    widget.fotos[index].url,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  tooltip: 'Fechar imagem ampliada',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
            if (widget.fotos.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_paginaAtual + 1} de ${widget.fotos.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

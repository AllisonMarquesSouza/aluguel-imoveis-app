import 'package:flutter/material.dart';

import '../models/imovel.dart';
import '../models/imovel_enums.dart';
import '../services/favoritos_service.dart';
import '../services/imovel_detalhe_service.dart';
import '../widgets/imovel_card.dart';

class FavoritosScreen extends StatefulWidget {
  final FavoritosService favoritosService;

  const FavoritosScreen({
    super.key,
    required this.favoritosService,
  });

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  late final ImovelDetalheService _imovelDetalheService;

  @override
  void initState() {
    super.initState();
    _imovelDetalheService = ImovelDetalheService();
    _atualizarSituacaoFavoritos();
  }

  Future<void> _atualizarSituacaoFavoritos() async {
    final favoritos = List<Imovel>.from(
      widget.favoritosService.favoritos.value,
    );

    for (final imovel in favoritos) {
      try {
        final detalhe = await _imovelDetalheService.buscarPorId(imovel.id);
        await widget.favoritosService.atualizarSituacao(
          imovel.id,
          detalhe.situacao,
        );
      } on ImovelIndisponivelException {
        await widget.favoritosService.atualizarSituacao(
          imovel.id,
          SituacaoImovel.despublicado,
        );
      } catch (_) {
        // Se a API falhar, mantém a situação salva no aparelho.
      }
    }
  }

  String _textoSituacao(SituacaoImovel situacao) {
    switch (situacao) {
      case SituacaoImovel.vendido:
        return 'Indisponível: vendido';
      case SituacaoImovel.alugado:
        return 'Indisponível: alugado';
      case SituacaoImovel.despublicado:
        return 'Indisponível: despublicado';
      case SituacaoImovel.disponivel:
        return 'Disponível';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus favoritos'),
      ),
      body: ValueListenableBuilder<List<Imovel>>(
        valueListenable: widget.favoritosService.favoritos,
        builder: (context, favoritos, _) {
          if (favoritos.isEmpty) {
            return const Center(
              child: Text('Você ainda não salvou nenhum imóvel.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoritos.length,
            itemBuilder: (context, index) {
              final imovel = favoritos[index];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imovel.situacao != SituacaoImovel.disponivel)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _textoSituacao(imovel.situacao),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ImovelCard(
                    imovel: imovel,
                    isFavorito: true,
                    onAlternarFavorito: () {
                      widget.favoritosService.alternar(imovel);
                    },
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/detalhes-imovel',
                        arguments: imovel,
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

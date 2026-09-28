import '../models/imovel.dart';

enum TipoOrdenacao { menorPreco, maiorPreco, maiorArea, maisRecentes }

abstract class ImovelService {
  Future<List<String>> getCidadesAtendidas();
  Future<List<Imovel>> getImoveis({
    required String cidade,
    String? busca,
    TipoOrdenacao? ordenacao,
    int pagina = 1,
  });
}

class ImovelServiceMock implements ImovelService {
  final List<String> _cidadesMock = [
    'São Paulo',
    'Rio de Janeiro',
    'Curitiba',
    'Belo Horizonte',
  ];

  final List<Imovel> _imoveisBase = [
    Imovel(
      id: '1',
      titulo: 'Apartamento de Luxo com Varanda',
      cidade: 'São Paulo',
      bairro: 'Moema',
      preco: 3500.0,
      areaM2: 75.0,
      quartos: 2,
      imagemUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
      natureza: NaturezaImovel.aluguel,
      dataCriacao: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Imovel(
      id: '2',
      titulo: 'Casa Moderna em Condomínio',
      cidade: 'São Paulo',
      bairro: 'Jardins',
      preco: 850000.0,
      areaM2: 210.0,
      quartos: 4,
      imagemUrl: 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800',
      natureza: NaturezaImovel.venda,
      dataCriacao: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Imovel(
      id: '3',
      titulo: 'Studio Totalmente Mobiliado',
      cidade: 'São Paulo',
      bairro: 'Pinheiros',
      preco: 2200.0,
      areaM2: 38.0,
      quartos: 1,
      imagemUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
      natureza: NaturezaImovel.aluguel,
      dataCriacao: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Future<List<String>> getCidadesAtendidas() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _cidadesMock;
  }

  @override
  Future<List<Imovel>> getImoveis({
    required String cidade,
    String? busca,
    TipoOrdenacao? ordenacao,
    int pagina = 1,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    var resultados = _imoveisBase.where((i) => i.cidade == cidade).toList();

    // Filtro por texto da busca
    if (busca != null && busca.isNotEmpty) {
      resultados = resultados.where((i) {
        final termo = busca.toLowerCase();
        return i.titulo.toLowerCase().contains(termo) ||
            i.bairro.toLowerCase().contains(termo);
      }).toList();
    }

    // Ordenação
    switch (ordenacao) {
      case TipoOrdenacao.menorPreco:
        resultados.sort((a, b) => a.preco.compareTo(b.preco));
        break;
      case TipoOrdenacao.maiorPreco:
        resultados.sort((a, b) => b.preco.compareTo(a.preco));
        break;
      case TipoOrdenacao.maiorArea:
        resultados.sort((a, b) => b.areaM2.compareTo(a.areaM2));
        break;
      case TipoOrdenacao.maisRecentes:
      default:
        resultados.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
        break;
    }

    return resultados;
  }
}
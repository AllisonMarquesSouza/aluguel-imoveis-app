import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/filtros_vitrine.dart';
import '../models/imovel.dart';
import '../models/imovel_enums.dart';

enum TipoOrdenacao { menorPreco, maiorPreco, maiorArea, maisRecentes }

class ResultadoBuscaImoveis {
  final List<Imovel> imoveis;
  final int total;

  const ResultadoBuscaImoveis({
    required this.imoveis,
    required this.total,
  });
}

abstract class ImovelService {
  Future<List<String>> getCidadesAtendidas();

  Future<ResultadoBuscaImoveis> getImoveis({
    required String cidade,
    String? busca,
    TipoOrdenacao? ordenacao,
    FiltrosVitrine filtros = const FiltrosVitrine(),
    int pagina = 1,
  });
}

class ImovelServiceMock implements ImovelService {
  final List<String> _cidadesMock = [
    'Serra Talhada',
    'Custódia',
    'Afogados da Ingazeira',
    'Flores',
  ];

  final List<Imovel> _imoveisBase = [
    Imovel(
      id: '1',
      titulo: 'Apartamento de Luxo com Varanda',
      cidade: 'Serra Talhada',
      bairro: 'Centro',
      preco: 3500.0,
      areaM2: 75.0,
      quartos: 2,
      imagemUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
      natureza: NaturezaImovel.apartamento,
      finalidade: FinalidadeImovel.aluguel,
      dataCriacao: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Imovel(
      id: '2',
      titulo: 'Casa Moderna em Condomínio',
      cidade: 'Custódia',
      bairro: 'Centro',
      preco: 850000.0,
      areaM2: 210.0,
      quartos: 4,
      imagemUrl: 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800',
      natureza: NaturezaImovel.casa,
      finalidade: FinalidadeImovel.venda,
      dataCriacao: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Imovel(
      id: '3',
      titulo: 'Studio Totalmente Mobiliado',
      cidade: 'Afogados da Ingazeira',
      bairro: 'Centro',
      preco: 2200.0,
      areaM2: 38.0,
      quartos: 1,
      imagemUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
      natureza: NaturezaImovel.apartamento,
      finalidade: FinalidadeImovel.aluguel,
      dataCriacao: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Future<List<String>> getCidadesAtendidas() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _cidadesMock;
  }

  @override
  Future<ResultadoBuscaImoveis> getImoveis({
  required String cidade,
  String? busca,
  TipoOrdenacao? ordenacao,
  FiltrosVitrine filtros = const FiltrosVitrine(),
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

      return ResultadoBuscaImoveis(
      imoveis: resultados,
      total: resultados.length,
    );
  }
}

class ImovelServiceApi extends ImovelServiceMock {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  @override
  Future<ResultadoBuscaImoveis> getImoveis({
    required String cidade,
    String? busca,
    TipoOrdenacao? ordenacao,
    FiltrosVitrine filtros = const FiltrosVitrine(),
    int pagina = 1,
  }) async {
    final parametros = <String, dynamic>{
      'cidade': cidade,
      'pagina': pagina.toString(),
      if (busca != null && busca.trim().isNotEmpty) 'busca': busca.trim(),
      if (ordenacao != null) 'ordenacao': ordenacao.name,
      for (final entrada in filtros.toQueryParameters().entries)
        entrada.key: entrada.value is List
            ? (entrada.value as List).map((valor) => valor.toString()).toList()
            : entrada.value.toString(),
    };

    final uri = Uri.parse('$_baseUrl/imoveis').replace(
      queryParameters: parametros,
    );

    final resposta = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (resposta.statusCode != 200) {
      throw Exception(
        'A API não conseguiu buscar os imóveis '
        '(HTTP ${resposta.statusCode}).',
      );
    }

    final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));

    if (corpo is! Map<String, dynamic> ||
        corpo['content'] is! List ||
        corpo['totalElements'] is! num) {
      throw const FormatException(
        'A resposta da API não está no formato esperado.',
      );
    }

    final imoveis = (corpo['content'] as List)
        .map(
          (item) => Imovel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    return ResultadoBuscaImoveis(
      imoveis: imoveis,
      total: (corpo['totalElements'] as num).toInt(),
    );
  }
}
import 'dart:convert';

import '../models/filtros_vitrine.dart';
import '../models/imovel.dart';
import 'api_client.dart';

enum TipoOrdenacao { menorPreco, maiorPreco, maiorArea, maisRecentes }

class ResultadoBuscaImoveis {
  final List<Imovel> imoveis;
  final int total;

  const ResultadoBuscaImoveis({required this.imoveis, required this.total});
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

class ImovelServiceApi implements ImovelService {
  final ApiClient _api;

  ImovelServiceApi({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  @override
  Future<List<String>> getCidadesAtendidas() async {
    final resposta = await _api.get('/cidade');
    final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
    if (corpo is! List) {
      throw const FormatException('A API retornou uma lista de cidades inválida.');
    }
    return corpo
        .map((item) => (item as Map)['nome']?.toString() ?? '')
        .where((nome) => nome.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<ResultadoBuscaImoveis> getImoveis({
    required String cidade,
    String? busca,
    TipoOrdenacao? ordenacao,
    FiltrosVitrine filtros = const FiltrosVitrine(),
    int pagina = 1,
  }) async {
    final resposta = await _api.get('/imovel');
    final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
    if (corpo is! List) {
      throw const FormatException('A API retornou uma lista de imóveis inválida.');
    }

    var imoveis = corpo
        .map((item) => Imovel.fromJson(Map<String, dynamic>.from(item as Map)))
        .where((imovel) => cidade.isEmpty || imovel.cidade.toLowerCase() == cidade.toLowerCase())
        .toList();

    if (filtros.natureza != null || filtros.quartosMinimos != null ||
        filtros.suitesMinimas != null || filtros.vagasMinimas != null ||
        filtros.areaMinimaM2 != null || filtros.areaMaximaM2 != null ||
        filtros.caracteristicas.isNotEmpty) {
      throw const ApiException(
        'A API ainda não informa todos os campos necessários para esses filtros.',
      );
    }

    final termo = busca?.trim().toLowerCase();
    if (termo != null && termo.isNotEmpty) {
      imoveis = imoveis.where((imovel) =>
          imovel.titulo.toLowerCase().contains(termo) ||
          imovel.bairro.toLowerCase().contains(termo)).toList();
    }

    imoveis = imoveis.where((imovel) {
      if (filtros.finalidade != null &&
          imovel.finalidade.name != filtros.finalidade!.toLowerCase()) {
        return false;
      }
      if (filtros.precoMinimo != null && imovel.preco < filtros.precoMinimo!) {
        return false;
      }
      if (filtros.precoMaximo != null && imovel.preco > filtros.precoMaximo!) {
        return false;
      }
      if (filtros.bairro != null &&
          !imovel.bairro.toLowerCase().contains(filtros.bairro!.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    switch (ordenacao) {
      case TipoOrdenacao.menorPreco:
        imoveis.sort((a, b) => a.preco.compareTo(b.preco));
        break;
      case TipoOrdenacao.maiorPreco:
        imoveis.sort((a, b) => b.preco.compareTo(a.preco));
        break;
      case TipoOrdenacao.maiorArea:
        imoveis.sort((a, b) => (b.areaM2 ?? 0).compareTo(a.areaM2 ?? 0));
        break;
      case TipoOrdenacao.maisRecentes:
      case null:
        // A API não fornece data de criação; preserva-se a ordem recebida.
        break;
    }

    return ResultadoBuscaImoveis(imoveis: imoveis, total: imoveis.length);
  }
}

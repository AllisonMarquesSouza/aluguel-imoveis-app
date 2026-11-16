import 'dart:convert';

import '../models/filtros_vitrine.dart';
import '../models/imovel.dart';
import '../models/imovel_enums.dart';
import 'api_client.dart';

enum TipoOrdenacao { menorPreco, maiorPreco, maiorArea, maisRecentes }

class ResultadoBuscaImoveis {
  final List<Imovel> imoveis;
  final int total;
  final List<String> caracteristicasDisponiveis;

  const ResultadoBuscaImoveis({
    required this.imoveis,
    required this.total,
    this.caracteristicasDisponiveis = const [],
  });
}

abstract class ImovelService {
  Future<List<String>> getCidadesAtendidas();

  Future<ResultadoBuscaImoveis> getImoveis({
    required String cidade,
    String? busca,
    TipoOrdenacao? ordenacao,
    FiltrosVitrine filtros = const FiltrosVitrine(),
    bool atualizarApi = false,
  });
}

class ImovelServiceApi implements ImovelService {
  final ApiClient _api;
  List<Imovel>? _imoveisCache;

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
    bool atualizarApi = false,
  }) async {
    if (_imoveisCache == null || atualizarApi) {
      final resposta = await _api.get('/imovel');
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is! List) {
        throw const FormatException('A API retornou uma lista de imóveis inválida.');
      }
      _imoveisCache = corpo
          .map((item) => Imovel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false);
    }

    final caracteristicasDisponiveis = _imoveisCache!
        .expand((imovel) => imovel.caracteristicas)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    var imoveis = _imoveisCache!
        .where((imovel) => cidade.isEmpty || imovel.cidade.toLowerCase() == cidade.toLowerCase())
        .toList();

    final termo = busca?.trim().toLowerCase();
    if (termo != null && termo.isNotEmpty) {
      imoveis = imoveis.where((imovel) =>
          imovel.titulo.toLowerCase().contains(termo) ||
          imovel.bairro.toLowerCase().contains(termo)).toList();
    }

    imoveis = imoveis.where((imovel) {
      final finalidadeFiltro = filtros.finalidade?.toLowerCase();
      final finalidadeCompativel = finalidadeFiltro == null ||
          (finalidadeFiltro == 'venda'
              ? imovel.finalidade != FinalidadeImovel.aluguel
              : finalidadeFiltro == 'aluguel'
                  ? imovel.finalidade != FinalidadeImovel.venda
                  : imovel.finalidade.name == finalidadeFiltro);
      if (!finalidadeCompativel) {
        return false;
      }
      final precoFiltrado = finalidadeFiltro == 'aluguel'
          ? imovel.valorAluguel
          : finalidadeFiltro == 'venda'
              ? imovel.valorVenda
              : imovel.preco;
      if (filtros.precoMinimo != null &&
          (precoFiltrado == null || precoFiltrado < filtros.precoMinimo!)) {
        return false;
      }
      if (filtros.precoMaximo != null &&
          (precoFiltrado == null || precoFiltrado > filtros.precoMaximo!)) {
        return false;
      }
      if (filtros.natureza != null &&
          imovel.natureza?.name != filtros.natureza!.toLowerCase()) {
        return false;
      }
      if (filtros.quartosMinimos != null &&
          (imovel.quartos == null || imovel.quartos! < filtros.quartosMinimos!)) {
        return false;
      }
      if (filtros.suitesMinimas != null &&
          (imovel.suites == null || imovel.suites! < filtros.suitesMinimas!)) {
        return false;
      }
      if (filtros.vagasMinimas != null &&
          (imovel.vagas == null || imovel.vagas! < filtros.vagasMinimas!)) {
        return false;
      }
      if (filtros.areaMinimaM2 != null &&
          (imovel.areaM2 == null || imovel.areaM2! < filtros.areaMinimaM2!)) {
        return false;
      }
      if (filtros.areaMaximaM2 != null &&
          (imovel.areaM2 == null || imovel.areaM2! > filtros.areaMaximaM2!)) {
        return false;
      }
      if (filtros.bairro != null &&
          !imovel.bairro.toLowerCase().contains(filtros.bairro!.toLowerCase())) {
        return false;
      }
      if (!filtros.caracteristicas.every((caracteristica) =>
          imovel.caracteristicas.any((nome) =>
              nome.toLowerCase() == caracteristica.toLowerCase()))) {
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

    return ResultadoBuscaImoveis(
      imoveis: imoveis,
      total: imoveis.length,
      caracteristicasDisponiveis: caracteristicasDisponiveis,
    );
  }
}

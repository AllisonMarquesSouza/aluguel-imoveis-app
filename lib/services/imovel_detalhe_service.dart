import 'dart:convert';

import '../models/imovel_detalhe.dart';
import 'api_client.dart';

class ImovelIndisponivelException implements Exception {
  const ImovelIndisponivelException();
}

class ImovelDetalheService {
  final ApiClient _api;

  ImovelDetalheService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<ImovelDetalhe> buscarPorId(String id) async {
    final resposta = await _api.get('/imovel/${Uri.encodeComponent(id)}');

    if (resposta.statusCode == 404) {
      throw const ImovelIndisponivelException();
    }

    final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));

    if (corpo is! Map<String, dynamic>) {
      throw const FormatException(
        'A resposta da API não está no formato esperado.',
      );
    }

    return ImovelDetalhe.fromJson(corpo);
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/imovel_detalhe.dart';

class ImovelDetalheService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  Future<ImovelDetalhe> buscarPorId(String id) async {
    final uri = Uri.parse(
      '$_baseUrl/imoveis/${Uri.encodeComponent(id)}',
    );

    final resposta = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (resposta.statusCode == 404) {
      throw Exception('Imóvel não encontrado ou indisponível.');
    }

    if (resposta.statusCode != 200) {
      throw Exception(
        'A API não conseguiu carregar o imóvel '
        '(HTTP ${resposta.statusCode}).',
      );
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
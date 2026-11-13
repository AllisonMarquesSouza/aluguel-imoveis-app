import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/perfil_publico.dart';

class PerfilNaoDisponivelException implements Exception {
  const PerfilNaoDisponivelException();
}

class PerfilPublicoService {
  static final Uri _baseUri = Uri.parse(
    const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080',
    ),
  );

  static Uri resolverUrl(String valor) {
    final uri = Uri.tryParse(valor);
    if (uri != null && uri.hasScheme) return uri;
    return _baseUri.resolve(valor);
  }

  Future<CorretorPublico> buscarCorretor(int id) async {
    final resposta = await http.get(_baseUri.resolve('/corretor/$id'));

    if (resposta.statusCode == 404) {
      throw const PerfilNaoDisponivelException();
    }

    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw Exception('Não foi possível carregar o perfil.');
    }

    final json = jsonDecode(utf8.decode(resposta.bodyBytes));
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Resposta de perfil inválida.');
    }

    return CorretorPublico.fromJson(json);
  }

  Future<EmpresaPublica> buscarEmpresa(int empresaId) async {
  final resposta = await http.get(_baseUri.resolve('/corretor'));

  if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
    throw Exception('Não foi possível carregar a empresa.');
  }

  final json = jsonDecode(utf8.decode(resposta.bodyBytes));

  if (json is! List) {
    throw const FormatException('Resposta de corretores inválida.');
  }

  for (final item in json) {
    if (item is! Map) continue;

    final corretor = CorretorPublico.fromJson(
      Map<String, dynamic>.from(item),
    );

    if (corretor.empresa?.id == empresaId) {
      return corretor.empresa!;
    }
  }

  throw const PerfilNaoDisponivelException();
}
}

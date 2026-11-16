import 'dart:convert';

import '../models/perfil_publico.dart';
import 'api_client.dart';

class PerfilNaoDisponivelException implements Exception {
  const PerfilNaoDisponivelException();
}

class PerfilPublicoService {
  final ApiClient _api;

  PerfilPublicoService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  static Uri resolverUrl(String value) => ApiClient.resolverUrl(value);

  Future<CorretorPublico> buscarCorretor(int id) async {
    try {
      final resposta = await _api.get('/corretor/$id');
      final json = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Resposta de perfil inválida.');
      }
      return CorretorPublico.fromJson(json);
    } on ApiNotFoundException {
      throw const PerfilNaoDisponivelException();
    }
  }

  Future<EmpresaPublica> buscarEmpresa(int empresaId) async {
    final resposta = await _api.get('/corretor');
    final json = jsonDecode(utf8.decode(resposta.bodyBytes));
    if (json is! List) {
      throw const FormatException('Resposta de corretores inválida.');
    }

    for (final item in json.whereType<Map>()) {
      final corretor = CorretorPublico.fromJson(
        Map<String, dynamic>.from(item),
      );
      if (corretor.empresa?.id == empresaId) return corretor.empresa!;
    }

    throw const PerfilNaoDisponivelException();
  }
}

import 'dart:convert';

import 'api_client.dart';

enum CanalContato {
  whatsapp,
  telefone,
  email;

  String get valorApi {
    switch (this) {
      case CanalContato.whatsapp:
        return 'WHATSAPP';
      case CanalContato.telefone:
        return 'TELEFONE';
      case CanalContato.email:
        return 'EMAIL';
    }
  }
}

class ContatoRegistrado {
  final String? telefone;
  final String? whatsapp;
  final String? email;
  final String? mensagem;

  const ContatoRegistrado({
    this.telefone,
    this.whatsapp,
    this.email,
    this.mensagem,
  });

  factory ContatoRegistrado.fromJson(Map<String, dynamic> json) {
    return ContatoRegistrado(
      telefone: json['telefone']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      email: json['email']?.toString(),
      mensagem: json['mensagem']?.toString(),
    );
  }

  String? destinoPara(CanalContato canal) {
    switch (canal) {
      case CanalContato.whatsapp:
        return whatsapp;
      case CanalContato.telefone:
        return telefone;
      case CanalContato.email:
        return email;
    }
  }
}

class ContatoService {
  final ApiClient _api;

  ContatoService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  Future<ContatoRegistrado> registrarNoImovel({
    required String imovelId,
    required CanalContato canal,
  }) {
    return _registrar(
      '/contato/imovel/${Uri.encodeComponent(imovelId)}',
      {'canal': canal.valorApi},
    );
  }

  Future<ContatoRegistrado> registrarNoPerfilDoCorretor({
    required String corretorId,
    required CanalContato canal,
    String? imovelId,
  }) {
    return _registrar(
      '/contato/corretor/${Uri.encodeComponent(corretorId)}',
      {
        'canal': canal.valorApi,
        'imovelId': ?imovelId,
      },
    );
  }

  Future<ContatoRegistrado> _registrar(
    String caminho,
    Map<String, dynamic> corpo,
  ) async {
    final resposta = await _api.postJson(caminho, corpo);
    final json = jsonDecode(utf8.decode(resposta.bodyBytes));

    if (json is! Map<String, dynamic>) {
      throw const FormatException(
        'A API retornou um registro de contato inválido.',
      );
    }

    return ContatoRegistrado.fromJson(json);
  }
}

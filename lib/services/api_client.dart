import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_session.dart';

class ApiException implements Exception {
  final String mensagem;

  const ApiException(this.mensagem);

  @override
  String toString() => mensagem;
}
class ApiNotFoundException extends ApiException {
  const ApiNotFoundException(super.mensagem);
}

class ApiAuthenticationException extends ApiException {
  const ApiAuthenticationException(super.mensagem);
}

class ApiClient {
  static const String _baseUrlConfigurada = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_baseUrlConfigurada.isNotEmpty) return _baseUrlConfigurada;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static Uri resolverUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return uri;
    return Uri.parse(baseUrl).resolve(value);
  }

  final http.Client _http;

  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  Uri uri(String path, [Map<String, String>? query]) =>
      resolverUrl(path).replace(queryParameters: query);

  Future<http.Response> get(String path, {Map<String, String>? query}) async {
    try {
      final token = AuthSession.instance.token;
      final headers = <String, String>{'Accept': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final response = await _http
          .get(uri(path, query), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 401 || response.statusCode == 403) {
        if (response.statusCode == 401) {
          unawaited(AuthSession.instance.encerrar());
        }
        throw ApiAuthenticationException(
          token == null
              ? 'Entre com uma conta de corretor ativa para consultar cidades e imóveis da sua empresa.'
              : 'A API recusou este acesso. Verifique se a conta é de um corretor ativo e tente entrar novamente.',
        );
      }
      if (response.statusCode == 404) {
        throw const ApiNotFoundException('O recurso solicitado não foi encontrado na API.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException('A API respondeu com erro HTTP ${response.statusCode}.');
      }
      return response;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Não foi possível conectar à API. Confira o endereço e se o servidor está disponível.',
      );
    }
  }

  Future<String> autenticar({required String email, required String senha}) async {
    try {
      final response = await _http
          .post(
            uri('/auth/login'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'email': email, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 15));

      final corpo = response.bodyBytes.isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 401) {
        throw const ApiException('Não foi possível entrar. Confira seus dados e tente novamente.');
      }
      if (response.statusCode == 403) {
        throw const ApiException('Não foi possível entrar. Confira seus dados e tente novamente.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const ApiException('Não foi possível entrar. Confira seus dados e tente novamente.');
      }
      if (corpo is! Map || corpo['token'] is! String || (corpo['token'] as String).isEmpty) {
        throw const FormatException('A resposta de autenticação não contém um token válido.');
      }
      return corpo['token'] as String;
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException('A API retornou uma resposta de autenticação inválida.');
    } catch (_) {
      throw const ApiException(
        'Não foi possível conectar à API. Confira o endereço e se o servidor está disponível.',
      );
    }
  }

  Future<http.Response> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      final token = AuthSession.instance.token;
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await _http
          .post(uri(path), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        if (response.statusCode == 401) {
          unawaited(AuthSession.instance.encerrar());
        }
        throw const ApiException('A API recusou o registro do contato.');
      }
      if (response.statusCode == 404) {
        throw const ApiException('O imóvel ou corretor não foi encontrado.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'Não foi possível registrar o contato (HTTP ${response.statusCode}).',
        );
      }
      return response;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Não foi possível conectar à API para registrar o contato.',
      );
    }
  }

}

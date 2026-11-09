import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String mensagem;

  const ApiException(this.mensagem);

  @override
  String toString() => mensagem;
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

  final http.Client _http;

  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  Uri uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<http.Response> get(String path, {Map<String, String>? query}) async {
    try {
      final response = await _http
          .get(uri(path, query), headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const ApiException(
          'A API exige autenticação para esta consulta. A vitrine pública ainda não está disponível nela.',
        );
      }
      if (response.statusCode == 404) {
        throw const ApiException('O recurso solicitado não foi encontrado na API.');
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
}

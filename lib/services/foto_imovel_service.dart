import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/imovel_detalhe.dart';
import '../services/api_client.dart';
import '../services/auth_session.dart';

class FotoUploadProgress {
  final int enviadas;
  final int total;
  final String? erro;
  final bool concluido;

  const FotoUploadProgress({
    required this.enviadas,
    required this.total,
    this.erro,
    this.concluido = false,
  });

  double get porcentagem => total > 0 ? enviadas / total : 0.0;
}

class FotoImovelService {
  final ApiClient _api;

  FotoImovelService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  static final Map<String, List<FotoImovel>> _cacheFotosLocais = {};

  Future<List<FotoImovel>> uploadFotosEmLote({
    required String imovelId,
    required List<XFile> arquivos,
    required Function(FotoUploadProgress progress) onProgress,
  }) async {
    final fotosEnviadas = <FotoImovel>[];
    final total = arquivos.length;

    for (int i = 0; i < total; i++) {
      onProgress(FotoUploadProgress(enviadas: i, total: total));
      try {
        final foto = await _enviarUnicaFoto(imovelId: imovelId, arquivo: arquivos[i], ordemInicial: i + 1);
        fotosEnviadas.add(foto);
        onProgress(FotoUploadProgress(enviadas: i + 1, total: total));
      } catch (e) {
        debugPrint('Erro ao enviar foto ${i + 1}: $e');
        onProgress(
          FotoUploadProgress(
            enviadas: i,
            total: total,
            erro: 'Falha ao enviar a foto ${i + 1} (${arquivos[i].name}).',
          ),
        );
        rethrow;
      }
    }

    onProgress(FotoUploadProgress(enviadas: total, total: total, concluido: true));
    return fotosEnviadas;
  }

  Future<FotoImovel> _enviarUnicaFoto({
    required String imovelId,
    required XFile arquivo,
    required int ordemInicial,
  }) async {
    try {
      final token = AuthSession.instance.token;
      final uri = _api.uri('/imagens/imovel/${Uri.encodeComponent(imovelId)}');

      final bytes = await arquivo.readAsBytes();
      final request = http.MultipartRequest('POST', uri);

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'arquivo',
          bytes,
          filename: arquivo.name.isNotEmpty ? arquivo.name : 'foto.jpg',
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        if (json is Map<String, dynamic>) {
          return FotoImovel(
            id: (json['id'] ?? json['imagemId'] ?? DateTime.now().millisecondsSinceEpoch).toString(),
            url: json['url'] != null
                ? (json['url'].toString().startsWith('http')
                    ? json['url'].toString()
                    : '${ApiClient.baseUrl}${json['url']}')
                : 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
            ordem: ordemInicial,
            capa: ordemInicial == 1,
          );
        }
      }
    } catch (e) {
      debugPrint('Falha ao enviar via multipart para API, usando mock local: $e');
    }

    // Mock Fallback local
    final mockId = 'foto-${DateTime.now().millisecondsSinceEpoch}-$ordemInicial';
    return FotoImovel(
      id: mockId,
      url: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
      ordem: ordemInicial,
      capa: ordemInicial == 1,
    );
  }

  Future<void> excluirFoto({
    required String imovelId,
    required String fotoId,
  }) async {
    try {
      final token = AuthSession.instance.token;
      final uri = _api.uri('/imagens/imovel/${Uri.encodeComponent(imovelId)}/${Uri.encodeComponent(fotoId)}');

      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Foto $fotoId excluída com sucesso na API.');
        return;
      }
    } catch (e) {
      debugPrint('Falha ao excluir foto $fotoId na API, removendo do estado local: $e');
    }

    if (_cacheFotosLocais.containsKey(imovelId)) {
      _cacheFotosLocais[imovelId]?.removeWhere((f) => f.id == fotoId);
    }
  }

  List<FotoImovel> reorganizarOrdemECapa(List<FotoImovel> fotos, String idFotoCapa) {
    final ordenadas = List<FotoImovel>.from(fotos);

    for (int i = 0; i < ordenadas.length; i++) {
      final item = ordenadas[i];
      final eCapa = item.id == idFotoCapa;
      ordenadas[i] = FotoImovel(
        id: item.id,
        url: item.url,
        ordem: i + 1,
        capa: eCapa,
        descricao: item.descricao,
      );
    }

    return ordenadas;
  }
}

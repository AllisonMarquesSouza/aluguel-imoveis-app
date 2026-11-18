import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/gestor_dashboard.dart';
import '../models/imovel_enums.dart';

import 'api_client.dart';
import 'contato_recebido_service.dart';

class GestorDashboardService {
  final ApiClient _api;

  GestorDashboardService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  static final GestorDashboardDados _mockDados = GestorDashboardDados(
    totaisEmpresa: const TotaisEmpresaSituacao(
      disponivel: 18,
      reservado: 3,
      vendido: 5,
      alugado: 12,
    ),
    metricasCorretores: const [
      MetricaCorretor(
        id: '11',
        nome: 'Carlos Silva',
        creci: '12345-F',
        totalImoveis: 14,
        totalContatos: 8,
        fotoUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400',
      ),
      MetricaCorretor(
        id: '12',
        nome: 'Ana Souza',
        creci: '54321-F',
        totalImoveis: 8,
        totalContatos: 12,
        fotoUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400',
      ),
      MetricaCorretor(
        id: '13',
        nome: 'João Santos',
        creci: '98765-F',
        totalImoveis: 5,
        totalContatos: 3,
        fotoUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400',
      ),
      MetricaCorretor(
        id: '14',
        nome: 'Mariana Lima',
        creci: '67890-F',
        totalImoveis: 11,
        totalContatos: 15,
        fotoUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400',
      ),
    ],
    mudancasRecentes: [
      MudancaSituacaoImovel(
        imovelId: '1',
        imovelCodigo: 'SP-101',
        imovelTitulo: 'Apartamento de Luxo com Varanda',
        situacaoAntiga: SituacaoImovel.disponivel,
        novaSituacao: SituacaoImovel.alugado,
        corretorNome: 'Carlos Silva',
        dataAlteracao: DateTime.now().subtract(const Duration(days: 1)),
      ),
      MudancaSituacaoImovel(
        imovelId: '2',
        imovelCodigo: 'SP-102',
        imovelTitulo: 'Casa Moderna em Condomínio',
        situacaoAntiga: SituacaoImovel.disponivel,
        novaSituacao: SituacaoImovel.vendido,
        corretorNome: 'Ana Souza',
        dataAlteracao: DateTime.now().subtract(const Duration(days: 3)),
      ),
      MudancaSituacaoImovel(
        imovelId: '3',
        imovelCodigo: 'SP-103',
        imovelTitulo: 'Studio Totalmente Mobiliado',
        situacaoAntiga: SituacaoImovel.disponivel,
        novaSituacao: SituacaoImovel.despublicado,
        corretorNome: 'Carlos Silva',
        dataAlteracao: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ],
  );

  Future<GestorDashboardDados> buscarDadosAcompanhamento({
    FiltroPeriodo periodo = FiltroPeriodo.todos,
  }) async {
    try {
      final queryParams = <String, String>{
        'periodo': periodo.name,
      };

      final resposta = await _api.get('/gestor/acompanhamento', query: queryParams);
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (corpo is Map<String, dynamic>) {
        return GestorDashboardDados.fromJson(corpo);
      }
    } catch (e) {
      debugPrint('Falha ao obter dados do acompanhamento do gestor da API, usando mock: $e');
    }

    return _mockDados;
  }
}

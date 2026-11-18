import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/contato_recebido.dart';
import '../services/api_client.dart';
import '../services/contato_service.dart';

enum FiltroPeriodo {
  todos,
  hoje,
  ultimos7Dias,
  ultimos30Dias;

  String get rotulo {
    switch (this) {
      case FiltroPeriodo.todos:
        return 'Todo o período';
      case FiltroPeriodo.hoje:
        return 'Hoje';
      case FiltroPeriodo.ultimos7Dias:
        return 'Últimos 7 dias';
      case FiltroPeriodo.ultimos30Dias:
        return 'Últimos 30 dias';
    }
  }
}

class ContatoRecebidoService {
  final ApiClient _api;

  ContatoRecebidoService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  // Armazenamento em memória local para o modo mock / fallback
  static final List<ContatoRecebido> _mockContatos = [
    ContatoRecebido(
      id: 'c-101',
      imovelId: '1',
      imovelTitulo: 'Apartamento de Luxo com Varanda',
      imovelCodigo: 'SP-101',
      imovelImagemUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
      canal: CanalContato.whatsapp,
      dataContato: DateTime.now().subtract(const Duration(hours: 2)),
      nomeCliente: 'Lucas Oliveira',
      telefoneCliente: '5511988881111',
      retorno: null, // Sem retorno anotado
    ),
    ContatoRecebido(
      id: 'c-102',
      imovelId: '2',
      imovelTitulo: 'Casa Moderna em Condomínio',
      imovelCodigo: 'SP-102',
      imovelImagemUrl: 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800',
      canal: CanalContato.telefone,
      dataContato: DateTime.now().subtract(const Duration(hours: 5)),
      nomeCliente: 'Mariana Santos',
      telefoneCliente: '5511977772222',
      retorno: RetornoContato.falei,
      observacaoRetorno: 'Cliente interessada na visita para o próximo sábado.',
    ),
    ContatoRecebido(
      id: 'c-103',
      imovelId: '1',
      imovelTitulo: 'Apartamento de Luxo com Varanda',
      imovelCodigo: 'SP-101',
      imovelImagemUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
      canal: CanalContato.email,
      dataContato: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      nomeCliente: 'Roberto Ferraz',
      emailCliente: 'roberto@email.com',
      retorno: null, // Sem retorno anotado
    ),
    ContatoRecebido(
      id: 'c-104',
      imovelId: '3',
      imovelTitulo: 'Studio Totalmente Mobiliado',
      imovelCodigo: 'SP-103',
      imovelImagemUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
      canal: CanalContato.whatsapp,
      dataContato: DateTime.now().subtract(const Duration(days: 3)),
      nomeCliente: 'Fernanda Lima',
      telefoneCliente: '5511966663333',
      retorno: RetornoContato.visitaAgendada,
      observacaoRetorno: 'Visita agendada para 20/11 às 14h.',
    ),
    ContatoRecebido(
      id: 'c-105',
      imovelId: '2',
      imovelTitulo: 'Casa Moderna em Condomínio',
      imovelCodigo: 'SP-102',
      imovelImagemUrl: 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800',
      canal: CanalContato.telefone,
      dataContato: DateTime.now().subtract(const Duration(days: 5)),
      nomeCliente: 'Bruno Castro',
      telefoneCliente: '5511955554444',
      retorno: RetornoContato.semResposta,
      observacaoRetorno: 'Liguei duas vezes, deu caixa postal.',
    ),
  ];

  Future<List<ContatoRecebido>> buscarContatosRecebidos({
    String? imovelId,
    FiltroPeriodo periodo = FiltroPeriodo.todos,
    bool? apenasSemRetorno,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (imovelId != null && imovelId.isNotEmpty) {
        queryParams['imovelId'] = imovelId;
      }

      final resposta = await _api.get('/contato/recebidos', query: queryParams);
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (corpo is List) {
        var lista = corpo
            .map((item) => ContatoRecebido.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();

        lista = _aplicarFiltrosLocais(lista, imovelId: imovelId, periodo: periodo, apenasSemRetorno: apenasSemRetorno);
        return lista;
      }
    } catch (e) {
      debugPrint('Falha ao buscar contatos da API, utilizando mock local: $e');
    }

    var listaMock = List<ContatoRecebido>.from(_mockContatos);
    return _aplicarFiltrosLocais(listaMock, imovelId: imovelId, periodo: periodo, apenasSemRetorno: apenasSemRetorno);
  }

  Future<ContatoRecebido> anotarRetorno({
    required String contatoId,
    required RetornoContato retorno,
    String? observacao,
  }) async {
    try {
      final resposta = await _api.postJson(
        '/contato/$contatoId/retorno',
        {
          'retorno': retorno.valorApi,
          'observacao': observacao ?? '',
        },
      );

      final json = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (json is Map<String, dynamic>) {
        final atualizado = ContatoRecebido.fromJson(json);
        _atualizarMock(atualizado);
        return atualizado;
      }
    } catch (e) {
      debugPrint('Falha ao gravar retorno na API, atualizando estado local: $e');
    }

    // Atualização local no mock
    final idx = _mockContatos.indexWhere((c) => c.id == contatoId);
    if (idx >= 0) {
      final itemAntigo = _mockContatos[idx];
      final itemNovo = itemAntigo.copyWith(
        retorno: retorno,
        observacaoRetorno: observacao,
      );
      _mockContatos[idx] = itemNovo;
      return itemNovo;
    }

    throw const FormatException('Contato não encontrado para atualizar retorno.');
  }

  Future<int> contarSemRetorno() async {
    final todos = await buscarContatosRecebidos();
    return todos.where((c) => !c.temRetornoAnotado).length;
  }

  List<ContatoRecebido> _aplicarFiltrosLocais(
    List<ContatoRecebido> lista, {
    String? imovelId,
    FiltroPeriodo periodo = FiltroPeriodo.todos,
    bool? apenasSemRetorno,
  }) {
    var resultado = List<ContatoRecebido>.from(lista);

    // 1. Filtro por imóvel
    if (imovelId != null && imovelId.isNotEmpty) {
      resultado = resultado.where((c) => c.imovelId == imovelId).toList();
    }

    // 2. Filtro por período
    final agora = DateTime.now();
    if (periodo == FiltroPeriodo.hoje) {
      final inicioHoje = DateTime(agora.year, agora.month, agora.day);
      resultado = resultado.where((c) => c.dataContato.isAfter(inicioHoje)).toList();
    } else if (periodo == FiltroPeriodo.ultimos7Dias) {
      final limite7Dias = agora.subtract(const Duration(days: 7));
      resultado = resultado.where((c) => c.dataContato.isAfter(limite7Dias)).toList();
    } else if (periodo == FiltroPeriodo.ultimos30Dias) {
      final limite30Dias = agora.subtract(const Duration(days: 30));
      resultado = resultado.where((c) => c.dataContato.isAfter(limite30Dias)).toList();
    }

    // 3. Filtro de apenas sem retorno anotado
    if (apenasSemRetorno == true) {
      resultado = resultado.where((c) => !c.temRetornoAnotado).toList();
    }

    // 4. Ordenação: Mais recentes primeiro (Critério 1)
    resultado.sort((a, b) => b.dataContato.compareTo(a.dataContato));

    return resultado;
  }

  void _atualizarMock(ContatoRecebido item) {
    final idx = _mockContatos.indexWhere((c) => c.id == item.id);
    if (idx >= 0) {
      _mockContatos[idx] = item;
    } else {
      _mockContatos.insert(0, item);
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/imovel.dart';
import '../models/imovel_enums.dart';

enum TipoOrdenacao { menorPreco, maiorPreco, maiorArea, maisRecentes }
enum CanalContato { whatsapp, telefone, email }

abstract class ImovelService {
  Future<List<String>> getCidadesAtendidas();
  Future<List<Imovel>> getImoveis({
    required String cidade,
    String? busca,
    TipoOrdenacao? ordenacao,
    int pagina = 1,
  });

  Future<void> registrarContato({
    required String imovelId,
    required String corretorTelefone,
    required CanalContato canal,
  });
}

class ImovelServiceApi implements ImovelService {
  final String baseUrl;
  final ImovelServiceMock _mockFallback = ImovelServiceMock();

  final Map<String, int> _cidadesIdsMap = {};

  ImovelServiceApi({
    this.baseUrl = 'http://localhost:8080',
  });

  @override
  Future<List<String>> getCidadesAtendidas() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/vitrine/cidades'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final cidades = <String>[];
        _cidadesIdsMap.clear();

        for (final item in data) {
          if (item is Map) {
            final id = (item['id'] as num?)?.toInt();
            final nome = item['nome']?.toString() ?? '';
            final uf = item['uf']?.toString() ?? '';
            if (nome.isNotEmpty && id != null) {
              final nomeComUf = uf.isNotEmpty ? '$nome - $uf' : nome;
              cidades.add(nomeComUf);
              _cidadesIdsMap[nome.toLowerCase()] = id;
              _cidadesIdsMap[nomeComUf.toLowerCase()] = id;
            }
          }
        }

        if (cidades.isNotEmpty) {
          return cidades;
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar cidades na rota publica /vitrine/cidades: $e');
    }

    return _mockFallback.getCidadesAtendidas();
  }

  @override
  Future<List<Imovel>> getImoveis({
    required String cidade,
    String? busca,
    TipoOrdenacao? ordenacao,
    int pagina = 1,
  }) async {
    try {
      if (_cidadesIdsMap.isEmpty) {
        await getCidadesAtendidas();
      }

      final cidadeLimpa = cidade.split(' - ').first.trim().toLowerCase();
      final cidadeId = _cidadesIdsMap[cidade.toLowerCase()] ??
          _cidadesIdsMap[cidadeLimpa] ??
          (_cidadesIdsMap.isNotEmpty ? _cidadesIdsMap.values.first : 1);

      final queryParams = <String, String>{
        'cidadeId': cidadeId.toString(),
      };

      if (busca != null && busca.isNotEmpty) {
        queryParams['texto'] = busca;
      }

      final uri = Uri.parse('$baseUrl/vitrine/imoveis').replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final dynamic json = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> content = json is Map && json['content'] is List
            ? json['content'] as List
            : (json is List ? json : []);

        var imoveis = content
            .map((item) => Imovel.fromJson(item as Map<String, dynamic>, baseUrl: baseUrl))
            .toList();

        if (busca != null && busca.isNotEmpty) {
          final termo = busca.toLowerCase();
          imoveis = imoveis.where((i) {
            return i.titulo.toLowerCase().contains(termo) ||
                i.bairro.toLowerCase().contains(termo) ||
                i.codigo.toLowerCase().contains(termo);
          }).toList();
        }

        switch (ordenacao) {
          case TipoOrdenacao.menorPreco:
            imoveis.sort((a, b) => a.preco.compareTo(b.preco));
            break;
          case TipoOrdenacao.maiorPreco:
            imoveis.sort((a, b) => b.preco.compareTo(a.preco));
            break;
          case TipoOrdenacao.maiorArea:
            imoveis.sort((a, b) => (b.areaM2 ?? 0).compareTo(a.areaM2 ?? 0));
            break;
          case TipoOrdenacao.maisRecentes:
          default:
            imoveis.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
            break;
        }

        // Retorna o resultado real obtido da API
        return imoveis;
      }
    } catch (e) {
      debugPrint('Erro ao buscar imoveis na rota publica /vitrine/imoveis: $e');
    }

    return _mockFallback.getImoveis(
      cidade: cidade,
      busca: busca,
      ordenacao: ordenacao,
      pagina: pagina,
    );
  }

  @override
  Future<void> registrarContato({
    required String imovelId,
    required String corretorTelefone,
    required CanalContato canal,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/vitrine/imoveis/$imovelId/contatos'),
            headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({'canal': canal.name.toUpperCase()}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Contato registrado com sucesso na rota publica da vitrine.');
        return;
      }
    } catch (e) {
      debugPrint('Erro ao registrar contato na vitrine publica: $e');
    }

    debugPrint('LOG API (Fallback): Contato registrado -> Imovel: $imovelId, Canal: ${canal.name}');
  }
}

class ImovelServiceMock implements ImovelService {
  final List<String> _cidadesMock = ['São Paulo - SP', 'Rio de Janeiro - RJ', 'Curitiba - PR', 'Belo Horizonte - MG'];

  final List<Imovel> _imoveisBase = [
    Imovel(
      id: '1',
      codigo: 'SP-101',
      titulo: 'Apartamento de Luxo com Varanda',
      cidade: 'São Paulo',
      bairro: 'Moema',
      preco: 3500.0,
      areaM2: 75.0,
      quartos: 2,
      imagemUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
      natureza: NaturezaImovel.apartamento,
      finalidade: FinalidadeImovel.aluguel,
      dataCriacao: DateTime.now().subtract(const Duration(days: 2)),
      corretorNome: 'Carlos Silva',
      corretorTelefone: '5511999999999',
      corretorEmail: 'carlos.corretor@email.com',
    ),
    Imovel(
      id: '2',
      codigo: 'SP-102',
      titulo: 'Casa Moderna em Condomínio',
      cidade: 'São Paulo',
      bairro: 'Jardins',
      preco: 850000.0,
      areaM2: 210.0,
      quartos: 4,
      imagemUrl: 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800',
      natureza: NaturezaImovel.casa,
      finalidade: FinalidadeImovel.venda,
      dataCriacao: DateTime.now().subtract(const Duration(days: 10)),
      corretorNome: 'Carlos Silva',
      corretorTelefone: '5511999999999',
      corretorEmail: 'carlos.corretor@email.com',
    ),
    Imovel(
      id: '3',
      codigo: 'SP-103',
      titulo: 'Studio Totalmente Mobiliado',
      cidade: 'São Paulo',
      bairro: 'Pinheiros',
      preco: 2200.0,
      areaM2: 38.0,
      quartos: 1,
      imagemUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
      natureza: NaturezaImovel.apartamento,
      finalidade: FinalidadeImovel.aluguel,
      dataCriacao: DateTime.now().subtract(const Duration(hours: 5)),
      corretorNome: 'Carlos Silva',
      corretorTelefone: '5511999999999',
      corretorEmail: 'carlos.corretor@email.com',
    ),
  ];

  @override
  Future<List<String>> getCidadesAtendidas() async => _cidadesMock;

  @override
  Future<List<Imovel>> getImoveis({
    required String cidade,
    String? busca,
    TipoOrdenacao? ordenacao,
    int pagina = 1,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final cidadeLimpa = cidade.split(' - ').first.trim().toLowerCase();
    var resultados = _imoveisBase
        .where((i) => i.cidade.toLowerCase().contains(cidadeLimpa))
        .toList();

    if (busca != null && busca.isNotEmpty) {
      resultados = resultados.where((i) {
        final termo = busca.toLowerCase();
        return i.titulo.toLowerCase().contains(termo) ||
            i.bairro.toLowerCase().contains(termo) ||
            i.codigo.toLowerCase().contains(termo);
      }).toList();
    }

    switch (ordenacao) {
      case TipoOrdenacao.menorPreco:
        resultados.sort((a, b) => a.preco.compareTo(b.preco));
        break;
      case TipoOrdenacao.maiorPreco:
        resultados.sort((a, b) => b.preco.compareTo(a.preco));
        break;
      case TipoOrdenacao.maiorArea:
        resultados.sort((a, b) => (b.areaM2 ?? 0).compareTo(a.areaM2 ?? 0));
        break;
      case TipoOrdenacao.maisRecentes:
      default:
        resultados.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
        break;
    }

    return resultados;
  }

  @override
  Future<void> registrarContato({
    required String imovelId,
    required String corretorTelefone,
    required CanalContato canal,
  }) async {
    debugPrint('LOG API (Mock): Contato registrado -> Imovel: $imovelId, Canal: ${canal.name}');
  }
}

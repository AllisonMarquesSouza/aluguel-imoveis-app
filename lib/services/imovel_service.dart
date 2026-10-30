import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/imovel.dart';

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
  final String email;
  final String senha;
  final ImovelServiceMock _mockFallback = ImovelServiceMock();

  String? _token;

  ImovelServiceApi({
    this.baseUrl = 'http://localhost:8080',
    this.email = 'corretor@imobiliaria.com',
    this.senha = 'senha-com-no-minimo-12',
  });

  Future<String?> _obterToken() async {
    if (_token != null) return _token;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'] as String?;
        return _token;
      } else {
        debugPrint('Erro no login da API (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('Falha ao autenticar com a API em $baseUrl: $e');
    }
    return null;
  }

  @override
  Future<List<String>> getCidadesAtendidas() async {
    try {
      final token = await _obterToken();
      if (token == null) {
        debugPrint('API indisponível ou não autenticada. Usando mock de cidades.');
        return await _mockFallback.getCidadesAtendidas();
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/cidade'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final cidades = data
            .map((item) => item['nome']?.toString() ?? '')
            .where((nome) => nome.isNotEmpty)
            .toList();

        if (cidades.isNotEmpty) {
          return cidades;
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar cidades na API: $e');
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
      final token = await _obterToken();
      if (token == null) {
        debugPrint('API indisponível ou não autenticada. Usando mock de imóveis.');
        return await _mockFallback.getImoveis(
          cidade: cidade,
          busca: busca,
          ordenacao: ordenacao,
          pagina: pagina,
        );
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/imovel'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        var imoveis = data
            .map((item) => Imovel.fromJson(item as Map<String, dynamic>, baseUrl: baseUrl))
            .toList();

        if (cidade.isNotEmpty) {
          final cidadeLower = cidade.toLowerCase();
          imoveis = imoveis
              .where((i) => i.cidade.toLowerCase().contains(cidadeLower))
              .toList();
        }

        if (busca != null && busca.isNotEmpty) {
          final termo = busca.toLowerCase();
          imoveis = imoveis.where((i) {
            return i.titulo.toLowerCase().contains(termo) ||
                i.bairro.toLowerCase().contains(termo);
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
            imoveis.sort((a, b) => b.areaM2.compareTo(a.areaM2));
            break;
          case TipoOrdenacao.maisRecentes:
          default:
            imoveis.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
            break;
        }

        if (imoveis.isNotEmpty) {
          return imoveis;
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar imóveis na API: $e');
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
    debugPrint('LOG API: Contato registrado -> Imóvel: $imovelId, Canal: ${canal.name}');
  }
}

class ImovelServiceMock implements ImovelService {
  final List<String> _cidadesMock = [
    'São Paulo',
    'Rio de Janeiro',
    'Curitiba',
    'Belo Horizonte',
  ];

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
      natureza: NaturezaImovel.aluguel,
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
      natureza: NaturezaImovel.venda,
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
      natureza: NaturezaImovel.aluguel,
      dataCriacao: DateTime.now().subtract(const Duration(hours: 5)),
      corretorNome: 'Carlos Silva',
      corretorTelefone: '5511999999999',
      corretorEmail: 'carlos.corretor@email.com',
    ),
  ];

  @override
  Future<List<String>> getCidadesAtendidas() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _cidadesMock;
  }

  @override
  Future<List<Imovel>> getImoveis({
    required String cidade,
    String? busca,
    TipoOrdenacao? ordenacao,
    int pagina = 1,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var resultados = _imoveisBase.where((i) => i.cidade == cidade).toList();

    if (busca != null && busca.isNotEmpty) {
      resultados = resultados.where((i) {
        final termo = busca.toLowerCase();
        return i.titulo.toLowerCase().contains(termo) ||
            i.bairro.toLowerCase().contains(termo);
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
        resultados.sort((a, b) => b.areaM2.compareTo(a.areaM2));
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
    debugPrint('LOG API (Mock): Contato registrado -> Imóvel: $imovelId, Canal: ${canal.name}');
  }
}

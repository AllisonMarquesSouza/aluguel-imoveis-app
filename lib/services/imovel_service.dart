import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/imovel.dart';

abstract class ImovelService {
  Future<List<String>> getCidadesAtendidas();
  Future<List<Imovel>> getImoveisPorCidade(String cidade);
}

// --------------------------------------------------------------------------
// IMPLEMENTAÇÃO REAL COM API (Para a tarefa A02)
// --------------------------------------------------------------------------
class ImovelServiceApi implements ImovelService {
  // Altere para a URL real do seu backend quando estiver pronto
  final String baseUrl = 'https://api.meuappimoveis.com.br/v1';

  @override
  Future<List<String>> getCidadesAtendidas() async {
    final response = await http.get(Uri.parse('$baseUrl/cidades'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((cidade) => cidade.toString()).toList();
    } else {
      throw Exception('Falha ao carregar cidades da API');
    }
  }

  @override
  Future<List<Imovel>> getImoveisPorCidade(String cidade) async {
    final response = await http.get(Uri.parse('$baseUrl/imoveis?cidade=$cidade'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Imovel.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar imóveis da API');
    }
  }
}

// --------------------------------------------------------------------------
// IMPLEMENTAÇÃO MOCK (Usada atualmente)
// --------------------------------------------------------------------------
class ImovelServiceMock implements ImovelService {
  final List<String> _cidadesMock = [
    'São Paulo',
    'Rio de Janeiro',
    'Curitiba',
    'Belo Horizonte',
  ];

  final List<Imovel> _imoveisMock = [
    Imovel(
      id: '1',
      titulo: 'Apartamento Centro',
      cidade: 'São Paulo',
      preco: 2500.0,
      quartos: 2,
      imagemUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2',
    ),
    Imovel(
      id: '2',
      titulo: 'Casa com Quintal',
      cidade: 'Curitiba',
      preco: 3200.0,
      quartos: 3,
      imagemUrl: 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914',
    ),
    Imovel(
      id: '3',
      titulo: 'Studio Moderno',
      cidade: 'São Paulo',
      preco: 1800.0,
      quartos: 1,
      imagemUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267',
    ),
  ];

  @override
  Future<List<String>> getCidadesAtendidas() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _cidadesMock;
  }

  @override
  Future<List<Imovel>> getImoveisPorCidade(String cidade) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _imoveisMock.where((item) => item.cidade == cidade).toList();
  }
}
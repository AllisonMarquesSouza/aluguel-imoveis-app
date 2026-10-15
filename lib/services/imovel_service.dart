import 'package:flutter/foundation.dart';
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

  // Método exigido para registrar a interação na API
  Future<void> registrarContato({
    required String imovelId,
    required String corretorTelefone,
    required CanalContato canal,
  });
}

class ImovelServiceMock implements ImovelService {
  final List<String> _cidadesMock = ['São Paulo', 'Rio de Janeiro', 'Curitiba'];

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
      dataCriacao: DateTime.now(),
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
    return _imoveisBase.where((i) => i.cidade == cidade).toList();
  }

  @override
  Future<void> registrarContato({
    required String imovelId,
    required String corretorTelefone,
    required CanalContato canal,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Registrado com sucesso na API para a caixa do corretor e painel do gestor
    debugPrint('LOG API: Contato registrado -> Imóvel: $imovelId, Canal: ${canal.name}');
  }
}
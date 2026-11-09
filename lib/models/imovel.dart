import 'imovel_enums.dart';
import '../services/api_client.dart';

class Imovel {
  final String id;
  final String titulo;
  final String cidade;
  final String bairro;
  final double preco;
  final double? areaM2;
  final int? quartos;
  final String imagemUrl;
  final NaturezaImovel? natureza;
  final FinalidadeImovel finalidade;
  final DateTime? dataCriacao;
  final SituacaoImovel? situacao;

  Imovel({
    required this.id,
    required this.titulo,
    required this.cidade,
    required this.bairro,
    required this.preco,
    required this.areaM2,
    required this.quartos,
    required this.imagemUrl,
    this.natureza,
    required this.dataCriacao,
    required this.finalidade,
    this.situacao = SituacaoImovel.disponivel,
  });

  Imovel copyWith({SituacaoImovel? situacao}) {
    return Imovel(
      id: id,
      titulo: titulo,
      cidade: cidade,
      bairro: bairro,
      preco: preco,
      areaM2: areaM2,
      quartos: quartos,
      imagemUrl: imagemUrl,
      natureza: natureza,
      dataCriacao: dataCriacao,
      finalidade: finalidade,
      situacao: situacao ?? this.situacao,
    );
  }

  factory Imovel.fromJson(Map<String, dynamic> json) {
    final endereco = json['endereco'] is Map
        ? Map<String, dynamic>.from(json['endereco'] as Map)
        : <String, dynamic>{};
    final finalidade = _finalidade(json['finalidade']);
    final fotos = json['fotos'] is List ? json['fotos'] as List : const [];
    Map? fotoCapa;
    for (final foto in fotos) {
      if (foto is Map && foto['capa'] == true) {
        fotoCapa = foto;
        break;
      }
    }
    fotoCapa ??= fotos.isEmpty ? null : fotos.first as Map;
    final rawImage = fotoCapa is Map ? fotoCapa['url']?.toString() : json['imagemUrl']?.toString();
    final imageUrl = rawImage == null || rawImage.isEmpty
        ? ''
        : rawImage.startsWith('http') ? rawImage : '${ApiClient.baseUrl}$rawImage';
    final preco = finalidade == FinalidadeImovel.venda
        ? json['valorVenda'] ?? json['preco']
        : json['valorAluguel'] ?? json['preco'];

    return Imovel(
      id: json['id'].toString(),
      titulo: json['titulo'] as String,
      cidade: (json['cidade'] ?? endereco['cidade'] ?? '').toString(),
      bairro: (json['bairro'] ?? endereco['bairro'] ?? '').toString(),
      preco: (preco as num?)?.toDouble() ?? 0,
      areaM2: (json['areaM2'] as num?)?.toDouble(),
      quartos: json['quartos'] as int?,
      imagemUrl: imageUrl,
      natureza: _natureza(json['natureza']),
      finalidade: finalidade,
      dataCriacao: _date(json['dataCriacao'] ?? json['criadoEm']),
      situacao: _lerSituacao(json['situacao']),
    );
  }
Map<String, dynamic> toJson() => {
      'id': id,
      'titulo': titulo,
      'cidade': cidade,
      'bairro': bairro,
      'preco': preco,
      'areaM2': areaM2,
      'quartos': quartos,
      'imagemUrl': imagemUrl,
      'natureza': natureza?.name,
      'finalidade': finalidade.name,
      'dataCriacao': dataCriacao?.toIso8601String(),
      'situacao': situacao?.name,
    };
}

NaturezaImovel? _natureza(dynamic value) {
  if (value == null) return null;
  final name = value.toString().trim().toLowerCase();
  for (final item in NaturezaImovel.values) {
    if (item.name == name) return item;
  }
  return null;
}

FinalidadeImovel _finalidade(dynamic value) {
  final name = value?.toString().trim().toLowerCase();
  return FinalidadeImovel.values.firstWhere(
    (item) => item.name == name,
    orElse: () => throw FormatException('Finalidade de imóvel inválida: $value'),
  );
}

DateTime? _date(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());

SituacaoImovel? _lerSituacao(dynamic valor) {
  if (valor == null) return null;
  final nome = valor?.toString().trim().toLowerCase();
  for (final situacao in SituacaoImovel.values) {
    if (situacao.name == nome) return situacao;
  }
  return null;
}

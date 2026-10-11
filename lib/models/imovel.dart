import 'imovel_enums.dart';

class Imovel {
  final String id;
  final String titulo;
  final String cidade;
  final String bairro;
  final double preco;
  final double areaM2;
  final int quartos;
  final String imagemUrl;
  final NaturezaImovel natureza;
  final FinalidadeImovel finalidade;
  final DateTime dataCriacao;
  final SituacaoImovel situacao;

  Imovel({
    required this.id,
    required this.titulo,
    required this.cidade,
    required this.bairro,
    required this.preco,
    required this.areaM2,
    required this.quartos,
    required this.imagemUrl,
    required this.natureza,
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
    return Imovel(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      cidade: json['cidade'] as String,
      bairro: json['bairro'] ?? 'Centro',
      preco: (json['preco'] as num).toDouble(),
      areaM2: (json['areaM2'] as num? ?? 60.0).toDouble(),
      quartos: json['quartos'] as int,
      imagemUrl: json['imagemUrl'] as String,
      natureza: NaturezaImovel.values.byName(
        (json['natureza'] as String).trim().toLowerCase(),
      ),
      finalidade: FinalidadeImovel.values.byName(
        (json['finalidade'] as String).trim().toLowerCase(),
      ),
      dataCriacao: DateTime.parse(
        json['dataCriacao'] ?? DateTime.now().toIso8601String(),
      ),
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
      'natureza': natureza.name,
      'finalidade': finalidade.name,
      'dataCriacao': dataCriacao.toIso8601String(),
      'situacao': situacao.name,
    };
}

SituacaoImovel _lerSituacao(dynamic valor) {
  final nome = valor?.toString().trim().toLowerCase();

  return SituacaoImovel.values.firstWhere(
    (situacao) => situacao.name == nome,
    orElse: () => SituacaoImovel.disponivel,
  );
}

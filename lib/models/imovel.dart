enum NaturezaImovel { aluguel, venda }

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
  final DateTime dataCriacao;

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
  });

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
      natureza: json['natureza'] == 'venda'
          ? NaturezaImovel.venda
          : NaturezaImovel.aluguel,
      dataCriacao: DateTime.parse(json['dataCriacao'] ?? DateTime.now().toIso8601String()),
    );
  }
}
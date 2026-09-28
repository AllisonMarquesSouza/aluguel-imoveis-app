class Imovel {
  final String id;
  final String titulo;
  final String cidade;
  final double preco;
  final int quartos;
  final String imagemUrl;

  Imovel({
    required this.id,
    required this.titulo,
    required this.cidade,
    required this.preco,
    required this.quartos,
    required this.imagemUrl,
  });

  // Converte a resposta da API (JSON) para a classe Imovel do Flutter
  factory Imovel.fromJson(Map<String, dynamic> json) {
    return Imovel(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      cidade: json['cidade'] as String,
      preco: (json['preco'] as num).toDouble(),
      quartos: json['quartos'] as int,
      imagemUrl: json['imagemUrl'] as String,
    );
  }
}
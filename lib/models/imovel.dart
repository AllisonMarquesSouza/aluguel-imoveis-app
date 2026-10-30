enum NaturezaImovel { aluguel, venda }

class Imovel {
  final String id;
  final String codigo;
  final String titulo;
  final String cidade;
  final String bairro;
  final double preco;
  final double areaM2;
  final int quartos;
  final String imagemUrl;
  final NaturezaImovel natureza;
  final DateTime dataCriacao;

  final String corretorNome;
  final String corretorTelefone;
  final String corretorEmail;

  Imovel({
    required this.id,
    required this.codigo,
    required this.titulo,
    required this.cidade,
    required this.bairro,
    required this.preco,
    required this.areaM2,
    required this.quartos,
    required this.imagemUrl,
    required this.natureza,
    required this.dataCriacao,
    required this.corretorNome,
    required this.corretorTelefone,
    required this.corretorEmail,
  });

  factory Imovel.fromJson(Map<String, dynamic> json, {String baseUrl = 'http://localhost:8080'}) {
    final idStr = json['id']?.toString() ?? '1';
    final codigoStr = json['codigo']?.toString() ?? 'IMO-$idStr';

    String cidadeNome = 'São Paulo';
    String bairroNome = 'Centro';

    if (json['endereco'] is Map<String, dynamic>) {
      final end = json['endereco'] as Map<String, dynamic>;
      cidadeNome = end['cidade']?.toString() ?? cidadeNome;
      bairroNome = end['bairro']?.toString() ?? bairroNome;
    } else {
      cidadeNome = json['cidade']?.toString() ?? cidadeNome;
      bairroNome = json['bairro']?.toString() ?? bairroNome;
    }

    final finalidade = json['finalidade']?.toString().toUpperCase();
    NaturezaImovel nat = NaturezaImovel.aluguel;
    double precoVal = 0.0;

    if (finalidade == 'VENDA' || json['natureza'] == 'venda') {
      nat = NaturezaImovel.venda;
      precoVal = (json['valorVenda'] as num?)?.toDouble() ??
          (json['preco'] as num?)?.toDouble() ??
          0.0;
    } else {
      nat = NaturezaImovel.aluguel;
      precoVal = (json['valorAluguel'] as num?)?.toDouble() ??
          (json['preco'] as num?)?.toDouble() ??
          0.0;
    }

    String imgUrl = 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800';
    if (json['fotos'] is List && (json['fotos'] as List).isNotEmpty) {
      final listFotos = json['fotos'] as List;
      final fotoCapa = listFotos.firstWhere(
        (f) => f is Map && f['capa'] == true,
        orElse: () => listFotos.first,
      );
      if (fotoCapa is Map && fotoCapa['url'] != null) {
        final rawUrl = fotoCapa['url'].toString();
        imgUrl = rawUrl.startsWith('http') ? rawUrl : '$baseUrl$rawUrl';
      }
    } else if (json['imagemUrl'] != null && json['imagemUrl'].toString().isNotEmpty) {
      final rawUrl = json['imagemUrl'].toString();
      imgUrl = rawUrl.startsWith('http') ? rawUrl : '$baseUrl$rawUrl';
    }

    DateTime dt = DateTime.now();
    if (json['criadoEm'] != null) {
      dt = DateTime.tryParse(json['criadoEm'].toString()) ?? dt;
    } else if (json['dataCriacao'] != null) {
      dt = DateTime.tryParse(json['dataCriacao'].toString()) ?? dt;
    }

    return Imovel(
      id: idStr,
      codigo: codigoStr,
      titulo: json['titulo']?.toString() ?? 'Imóvel sem título',
      cidade: cidadeNome,
      bairro: bairroNome,
      preco: precoVal,
      areaM2: (json['areaM2'] as num? ?? 60.0).toDouble(),
      quartos: (json['quartos'] as int? ?? 2),
      imagemUrl: imgUrl,
      natureza: nat,
      dataCriacao: dt,
      corretorNome: json['nomeCorretor']?.toString() ?? json['corretorNome']?.toString() ?? 'Carlos Silva',
      corretorTelefone: json['corretorTelefone']?.toString() ?? '5511999999999',
      corretorEmail: json['corretorEmail']?.toString() ?? 'corretor@imobiliaria.com',
    );
  }
}

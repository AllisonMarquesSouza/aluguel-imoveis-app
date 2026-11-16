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

  factory Imovel.fromJson(
    Map<String, dynamic> json, {
    String baseUrl = 'http://localhost:8080',
  }) {
    final idStr = json['id']?.toString() ?? '1';
    final codigoStr = json['codigo']?.toString() ?? 'IMO-$idStr';

    String cidadeNome = 'São Paulo';
    String bairroNome = 'Centro';

    final endereco = json['endereco'];
    if (endereco is Map) {
      cidadeNome = (endereco['cidade'] ?? json['cidade'] ?? cidadeNome).toString();
      bairroNome = (endereco['bairro'] ?? json['bairro'] ?? bairroNome).toString();
    } else {
      cidadeNome = (json['cidade'] ?? cidadeNome).toString();
      bairroNome = (json['bairro'] ?? bairroNome).toString();
    }

    final finalidade = json['finalidade']?.toString().toUpperCase();
    final naturezaRaw = json['natureza']?.toString();
    NaturezaImovel nat = NaturezaImovel.aluguel;
    double precoVal = 0.0;

    if (finalidade == 'VENDA' || naturezaRaw == 'venda') {
      nat = NaturezaImovel.venda;
      precoVal = ((json['valorVenda'] as num?) ?? (json['preco'] as num?) ?? 0).toDouble();
    } else {
      nat = NaturezaImovel.aluguel;
      precoVal = ((json['valorAluguel'] as num?) ?? (json['preco'] as num?) ?? 0).toDouble();
    }

    String imgUrl = 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800';
    final fotos = json['fotos'];
    if (fotos is List && fotos.isNotEmpty) {
      final fotoCapa = fotos.firstWhere(
        (f) => f is Map && f['capa'] == true,
        orElse: () => fotos.first,
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
      corretorNome: json['nomeCorretor']?.toString() ??
          json['corretorNome']?.toString() ??
          'Corretor Parceiro',
      corretorTelefone: json['corretorTelefone']?.toString() ?? '5511999999999',
      corretorEmail: json['corretorEmail']?.toString() ?? 'corretor@imobiliaria.com',
    );
  }
}

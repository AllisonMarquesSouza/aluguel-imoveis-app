import 'imovel_enums.dart';

class Imovel {
  final String id;
  final String codigo;
  final String titulo;
  final String cidade;
  final String bairro;
  final double preco;
  final double? valorVenda;
  final double? valorAluguel;
  final double? valorCondominio;
  final double? valorIptu;
  final double? areaM2;
  final int? quartos;
  final int? suites;
  final int? vagas;
  final List<String> caracteristicas;
  final Map<String, dynamic> detalhes;
  final String imagemUrl;
  final NaturezaImovel natureza;
  final FinalidadeImovel finalidade;
  final SituacaoImovel? situacao;
  final DateTime dataCriacao;

  final String corretorNome;
  final String corretorTelefone;
  final String corretorEmail;

  const Imovel({
    required this.id,
    this.codigo = '',
    required this.titulo,
    required this.cidade,
    required this.bairro,
    required this.preco,
    this.valorVenda,
    this.valorAluguel,
    this.valorCondominio,
    this.valorIptu,
    this.areaM2,
    this.quartos,
    this.suites,
    this.vagas,
    this.caracteristicas = const [],
    this.detalhes = const {},
    required this.imagemUrl,
    this.natureza = NaturezaImovel.apartamento,
    this.finalidade = FinalidadeImovel.aluguel,
    this.situacao,
    required this.dataCriacao,
    this.corretorNome = 'Carlos Silva',
    this.corretorTelefone = '5511999999999',
    this.corretorEmail = 'carlos.corretor@email.com',
  });

  Imovel copyWith({
    String? id,
    String? codigo,
    String? titulo,
    String? cidade,
    String? bairro,
    double? preco,
    double? valorVenda,
    double? valorAluguel,
    double? valorCondominio,
    double? valorIptu,
    double? areaM2,
    int? quartos,
    int? suites,
    int? vagas,
    List<String>? caracteristicas,
    Map<String, dynamic>? detalhes,
    String? imagemUrl,
    NaturezaImovel? natureza,
    FinalidadeImovel? finalidade,
    SituacaoImovel? situacao,
    DateTime? dataCriacao,
    String? corretorNome,
    String? corretorTelefone,
    String? corretorEmail,
  }) {
    return Imovel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      titulo: titulo ?? this.titulo,
      cidade: cidade ?? this.cidade,
      bairro: bairro ?? this.bairro,
      preco: preco ?? this.preco,
      valorVenda: valorVenda ?? this.valorVenda,
      valorAluguel: valorAluguel ?? this.valorAluguel,
      valorCondominio: valorCondominio ?? this.valorCondominio,
      valorIptu: valorIptu ?? this.valorIptu,
      areaM2: areaM2 ?? this.areaM2,
      quartos: quartos ?? this.quartos,
      suites: suites ?? this.suites,
      vagas: vagas ?? this.vagas,
      caracteristicas: caracteristicas ?? this.caracteristicas,
      detalhes: detalhes ?? this.detalhes,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      natureza: natureza ?? this.natureza,
      finalidade: finalidade ?? this.finalidade,
      situacao: situacao ?? this.situacao,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      corretorNome: corretorNome ?? this.corretorNome,
      corretorTelefone: corretorTelefone ?? this.corretorTelefone,
      corretorEmail: corretorEmail ?? this.corretorEmail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'titulo': titulo,
      'cidade': cidade,
      'bairro': bairro,
      'preco': preco,
      'valorVenda': valorVenda,
      'valorAluguel': valorAluguel,
      'valorCondominio': valorCondominio,
      'valorIptu': valorIptu,
      'areaM2': areaM2,
      'quartos': quartos,
      'suites': suites,
      'vagas': vagas,
      'caracteristicas': caracteristicas,
      'detalhes': detalhes,
      'imagemUrl': imagemUrl,
      'natureza': natureza.name,
      'finalidade': finalidade.name,
      'situacao': situacao?.name,
      'dataCriacao': dataCriacao.toIso8601String(),
      'corretorNome': corretorNome,
      'corretorTelefone': corretorTelefone,
      'corretorEmail': corretorEmail,
    };
  }

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

    final finalidadeRaw = json['finalidade']?.toString().toLowerCase();
    FinalidadeImovel fin = FinalidadeImovel.aluguel;
    if (finalidadeRaw == 'venda') {
      fin = FinalidadeImovel.venda;
    } else if (finalidadeRaw == 'venda_e_aluguel' || finalidadeRaw == 'vendaealuguel') {
      fin = FinalidadeImovel.vendaEAluguel;
    }

    final naturezaRaw = json['natureza']?.toString().toLowerCase();
    NaturezaImovel nat = NaturezaImovel.apartamento;
    if (naturezaRaw == 'casa') nat = NaturezaImovel.casa;
    if (naturezaRaw == 'terreno') nat = NaturezaImovel.terreno;
    if (naturezaRaw == 'lote') nat = NaturezaImovel.lote;

    final double? vVenda = (json['valorVenda'] as num?)?.toDouble();
    final double? vAluguel = (json['valorAluguel'] as num?)?.toDouble();

    double precoVal = (vAluguel ?? vVenda ?? (json['preco'] as num?) ?? 0).toDouble();

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

    SituacaoImovel? sit;
    if (json['situacao'] != null) {
      final s = json['situacao'].toString().toLowerCase();
      for (final v in SituacaoImovel.values) {
        if (v.name == s) sit = v;
      }
    }

    final caracs = (json['caracteristicas'] as List?)
            ?.map((c) => c is Map ? (c['nome']?.toString() ?? '') : c.toString())
            .where((str) => str.isNotEmpty)
            .toList() ??
        const [];

    return Imovel(
      id: idStr,
      codigo: codigoStr,
      titulo: json['titulo']?.toString() ?? 'Imóvel sem título',
      cidade: cidadeNome,
      bairro: bairroNome,
      preco: precoVal,
      valorVenda: vVenda,
      valorAluguel: vAluguel,
      valorCondominio: (json['valorCondominio'] as num?)?.toDouble(),
      valorIptu: (json['valorIptu'] as num?)?.toDouble(),
      areaM2: (json['areaM2'] as num?)?.toDouble(),
      quartos: (json['quartos'] as num?)?.toInt(),
      suites: (json['suites'] as num?)?.toInt(),
      vagas: (json['vagas'] as num?)?.toInt(),
      caracteristicas: caracs,
      detalhes: Map<String, dynamic>.from(json['detalhes'] as Map? ?? const {}),
      imagemUrl: imgUrl,
      natureza: nat,
      finalidade: fin,
      situacao: sit,
      dataCriacao: dt,
      corretorNome: json['nomeCorretor']?.toString() ??
          json['corretorNome']?.toString() ??
          'Carlos Silva',
      corretorTelefone: json['corretorTelefone']?.toString() ?? '5511999999999',
      corretorEmail: json['corretorEmail']?.toString() ?? 'corretor@imobiliaria.com',
    );
  }
}

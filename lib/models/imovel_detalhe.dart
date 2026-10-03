enum NaturezaImovel { casa, apartamento, terreno, lote }

enum FinalidadeImovel { venda, aluguel }

class LocalizacaoImovel {
  final String cidade;
  final String uf;
  final String bairro;

  const LocalizacaoImovel({
    required this.cidade,
    required this.uf,
    required this.bairro,
  });

  factory LocalizacaoImovel.fromJson(Map<String, dynamic> json) {
    return LocalizacaoImovel(
      cidade: json['cidade'] as String,
      uf: json['uf'] as String,
      bairro: json['bairro'] as String,
    );
  }
}

class FotoImovel {
  final String id;
  final String url;
  final int ordem;
  final bool capa;
  final String? descricao;

  const FotoImovel({
    required this.id,
    required this.url,
    required this.ordem,
    required this.capa,
    this.descricao,
  });

  factory FotoImovel.fromJson(Map<String, dynamic> json) {
    return FotoImovel(
      id: json['id'].toString(),
      url: json['url'] as String,
      ordem: json['ordem'] as int,
      capa: json['capa'] as bool,
      descricao: json['descricao'] as String?,
    );
  }
}

class CaracteristicaImovel {
  final String id;
  final String nome;

  const CaracteristicaImovel({
    required this.id,
    required this.nome,
  });

  factory CaracteristicaImovel.fromJson(Map<String, dynamic> json) {
    return CaracteristicaImovel(
      id: json['id'].toString(),
      nome: json['nome'] as String,
    );
  }
}

class PrecoVenda {
  final double valor;
  final String moeda;

  const PrecoVenda({
    required this.valor,
    required this.moeda,
  });

  factory PrecoVenda.fromJson(Map<String, dynamic> json) {
    return PrecoVenda(
      valor: (json['valor'] as num).toDouble(),
      moeda: json['moeda'] as String,
    );
  }
}

class CorretorResumo {
  final String id;
  final String nome;
  final String creci;
  final String fotoUrl;

  const CorretorResumo({
    required this.id,
    required this.nome,
    required this.creci,
    required this.fotoUrl,
  });

  factory CorretorResumo.fromJson(Map<String, dynamic> json) {
    return CorretorResumo(
      id: json['id'].toString(),
      nome: json['nome'] as String,
      creci: json['creci'] as String,
      fotoUrl: json['fotoUrl'] as String,
    );
  }
}

class ImovelDetalhe {
  final String id;
  final String titulo;
  final String descricao;
  final NaturezaImovel natureza;
  final List<FinalidadeImovel> finalidades;
  final LocalizacaoImovel localizacao;

  // Os campos de detalhes variam conforme a natureza do imóvel.
  // Mantemos o JSON original até a equipe da API confirmar todos os formatos.
  final Map<String, dynamic> detalhes;

  final PrecoVenda? venda;
  final double? aluguelMensal;
  final double? condominioMensal;
  final double? iptuAnual;
  final List<CaracteristicaImovel> caracteristicas;
  final List<FotoImovel> fotos;
  final CorretorResumo corretor;

  const ImovelDetalhe({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.natureza,
    required this.finalidades,
    required this.localizacao,
    required this.detalhes,
    required this.venda,
    required this.aluguelMensal,
    required this.condominioMensal,
    required this.iptuAnual,
    required this.caracteristicas,
    required this.fotos,
    required this.corretor,
  });

  factory ImovelDetalhe.fromJson(Map<String, dynamic> json) {
    final valores = json['valores'] as Map<String, dynamic>;
    final vendaJson = valores['venda'] as Map<String, dynamic>?;

    return ImovelDetalhe(
      id: json['id'].toString(),
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String,
      natureza: _lerNatureza(json['natureza'] as String),
      finalidades: (json['finalidades'] as List<dynamic>)
          .map((valor) => _lerFinalidade(valor as String))
          .toList(),
      localizacao: LocalizacaoImovel.fromJson(
        json['localizacao'] as Map<String, dynamic>,
      ),
      detalhes: Map<String, dynamic>.from(
        json['detalhes'] as Map,
      ),
      venda: vendaJson == null ? null : PrecoVenda.fromJson(vendaJson),
      aluguelMensal: _lerNumeroOpcional(valores['aluguelMensal']),
      condominioMensal: _lerNumeroOpcional(valores['condominioMensal']),
      iptuAnual: _lerNumeroOpcional(valores['iptuAnual']),
      caracteristicas: (json['caracteristicas'] as List<dynamic>)
          .map(
            (item) => CaracteristicaImovel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      fotos: (json['fotos'] as List<dynamic>)
          .map(
            (item) => FotoImovel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      corretor: CorretorResumo.fromJson(
        json['corretor'] as Map<String, dynamic>,
      ),
    );
  }
}

NaturezaImovel _lerNatureza(String valor) {
  switch (valor.toUpperCase()) {
    case 'CASA':
      return NaturezaImovel.casa;
    case 'APARTAMENTO':
      return NaturezaImovel.apartamento;
    case 'TERRENO':
      return NaturezaImovel.terreno;
    case 'LOTE':
      return NaturezaImovel.lote;
    default:
      throw FormatException('Natureza de imóvel desconhecida: $valor');
  }
}

FinalidadeImovel _lerFinalidade(String valor) {
  switch (valor.toUpperCase()) {
    case 'VENDA':
      return FinalidadeImovel.venda;
    case 'ALUGUEL':
      return FinalidadeImovel.aluguel;
    default:
      throw FormatException('Finalidade desconhecida: $valor');
  }
}

double? _lerNumeroOpcional(dynamic valor) {
  return valor == null ? null : (valor as num).toDouble();
}
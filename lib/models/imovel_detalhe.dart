import 'imovel_enums.dart' show SituacaoImovel;
import '../services/api_client.dart';

enum NaturezaImovel { casa, apartamento, terreno, lote }

enum FinalidadeImovel { venda, aluguel }

class LocalizacaoImovel {
  final String cidade;
  final String uf;
  final String bairro;
  final double? latitude;
  final double? longitude;

  const LocalizacaoImovel({
    required this.cidade,
    required this.uf,
    required this.bairro,
    this.latitude,
    this.longitude,
  });

  factory LocalizacaoImovel.fromJson(Map<String, dynamic> json) {
    return LocalizacaoImovel(
      cidade: json['cidade']?.toString() ?? '',
      uf: json['uf']?.toString() ?? '',
      bairro: json['bairro']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
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
  final String? imovelIdReferencia;

  const CorretorResumo({
    required this.id,
    required this.nome,
    required this.creci,
    required this.fotoUrl,
    this.imovelIdReferencia,
  });

  factory CorretorResumo.fromJson(Map<String, dynamic> json) {
    return CorretorResumo(
      id: json['id'].toString(),
      nome: json['nome'] as String,
      creci: json['creci'] as String,
      fotoUrl: json['fotoUrl'] as String,
    );
  }

  CorretorResumo comImovelReferencia(String imovelId) {
    return CorretorResumo(
      id: id,
      nome: nome,
      creci: creci,
      fotoUrl: fotoUrl,
      imovelIdReferencia: imovelId,
    );
  }
}

class ImovelDetalhe {
  final String id;
  final String titulo;
  final String descricao;
  final NaturezaImovel? natureza;
  final SituacaoImovel? situacao;
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
  final CorretorResumo? corretor;

  const ImovelDetalhe({
    required this.id,
    required this.titulo,
    required this.descricao,
    this.natureza,
    required this.finalidades,
    required this.localizacao,
    required this.detalhes,
    required this.venda,
    required this.aluguelMensal,
    required this.condominioMensal,
    required this.iptuAnual,
    required this.caracteristicas,
    required this.fotos,
    this.situacao,
    this.corretor,
  });

  factory ImovelDetalhe.fromJson(Map<String, dynamic> json) {
    final endereco = Map<String, dynamic>.from(
      (json['endereco'] ?? json['localizacao']) as Map,
    );
    final valores = json['valores'] is Map
        ? Map<String, dynamic>.from(json['valores'] as Map)
        : json;
    final vendaJson = valores['venda'] as Map<String, dynamic>?;
    final finalidade = json['finalidade']?.toString();
    final corretorJson = json['corretor'] is Map
        ? Map<String, dynamic>.from(json['corretor'] as Map)
        : null;
    final fotos = (json['fotos'] as List? ?? const []).map((item) {
      final foto = Map<String, dynamic>.from(item as Map);
      final url = foto['url']?.toString() ?? '';
      return FotoImovel(
        id: (foto['id'] ?? '').toString(),
        url: url.startsWith('http') ? url : '${ApiClient.baseUrl}$url',
        ordem: (foto['ordem'] as num?)?.toInt() ?? 0,
        capa: foto['capa'] == true,
      );
    }).toList();

    return ImovelDetalhe(
      id: json['id'].toString(),
      titulo: json['titulo']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      natureza: json['natureza'] == null ? null : _lerNatureza(json['natureza'] as String),
      finalidades: (json['finalidades'] as List<dynamic>? ??
              (finalidade == null ? const [] : [finalidade]))
          .map((valor) => _lerFinalidade(valor as String))
          .toList(),
      localizacao: LocalizacaoImovel.fromJson(
        endereco,
      ),
      situacao: _lerSituacaoImovel(json['situacao']),
      detalhes: Map<String, dynamic>.from(json['detalhes'] as Map? ?? const {}),
      venda: vendaJson != null
          ? PrecoVenda.fromJson(vendaJson)
          : _lerNumeroOpcional(valores['valorVenda']) == null
              ? null
              : PrecoVenda(valor: _lerNumeroOpcional(valores['valorVenda'])!, moeda: 'BRL'),
      aluguelMensal: _lerNumeroOpcional(valores['aluguelMensal'] ?? valores['valorAluguel']),
      condominioMensal: _lerNumeroOpcional(valores['condominioMensal'] ?? valores['valorCondominio']),
      iptuAnual: _lerNumeroOpcional(valores['iptuAnual'] ?? valores['valorIptu']),
      caracteristicas: (json['caracteristicas'] as List<dynamic>)
          .map(
            (item) => CaracteristicaImovel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      fotos: fotos,
      corretor: corretorJson == null
          ? (json['corretorId'] == null && json['nomeCorretor'] == null
              ? null
              : CorretorResumo(id: json['corretorId'].toString(), nome: json['nomeCorretor']?.toString() ?? '', creci: '', fotoUrl: ''))
          : CorretorResumo.fromJson(corretorJson),
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

SituacaoImovel? _lerSituacaoImovel(dynamic valor) {
  if (valor == null) return null;
  final nome = valor?.toString().trim().toLowerCase();
  for (final situacao in SituacaoImovel.values) {
    if (situacao.name == nome) return situacao;
  }
  return null;
}

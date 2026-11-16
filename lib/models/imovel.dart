import '../services/api_client.dart';
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
  final NaturezaImovel? natureza;
  final FinalidadeImovel finalidade;
  final DateTime? dataCriacao;
  final SituacaoImovel? situacao;
  final int? corretorId;
  final int? empresaId;
  final String corretorNome;

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
    this.natureza,
    this.finalidade = FinalidadeImovel.venda,
    this.dataCriacao,
    this.situacao,
    this.corretorId,
    this.empresaId,
    this.corretorNome = '',
  });

  Imovel copyWith({SituacaoImovel? situacao}) => Imovel(
        id: id,
        codigo: codigo,
        titulo: titulo,
        cidade: cidade,
        bairro: bairro,
        preco: preco,
        valorVenda: valorVenda,
        valorAluguel: valorAluguel,
        valorCondominio: valorCondominio,
        valorIptu: valorIptu,
        areaM2: areaM2,
        quartos: quartos,
        suites: suites,
        vagas: vagas,
        caracteristicas: caracteristicas,
        detalhes: detalhes,
        imagemUrl: imagemUrl,
        natureza: natureza,
        finalidade: finalidade,
        dataCriacao: dataCriacao,
        situacao: situacao ?? this.situacao,
        corretorId: corretorId,
        empresaId: empresaId,
        corretorNome: corretorNome,
      );

  factory Imovel.fromJson(Map<String, dynamic> json) {
    final endereco = _map(json['endereco']);
    final casa = _map(json['casa']);
    final terreno = _map(json['terreno']);
    final finalidade = _lerFinalidade(json['finalidade']);
    final precoSalvo = _number(json['preco']);
    final valorVenda = _number(json['valorVenda']) ??
        (finalidade == FinalidadeImovel.aluguel ? null : precoSalvo);
    final valorAluguel = _number(json['valorAluguel']) ??
        (finalidade == FinalidadeImovel.venda ? null : precoSalvo);
    final area = _number(casa['areaConstruida']) ??
        _number(casa['areaTerreno']) ??
        _number(terreno['areaTotal']) ??
        _number(json['areaM2']);
    final foto = _fotoCapa(json['fotos']);
    final urlImagem = foto?['url']?.toString() ?? json['imagemUrl']?.toString() ?? '';

    return Imovel(
      id: json['id'].toString(),
      codigo: json['codigo']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      cidade: (endereco['cidade'] ?? json['cidade'] ?? '').toString(),
      bairro: (endereco['bairro'] ?? json['bairro'] ?? '').toString(),
      preco: finalidade == FinalidadeImovel.aluguel
          ? valorAluguel ?? 0
          : valorVenda ?? valorAluguel ?? 0,
      valorVenda: valorVenda,
      valorAluguel: valorAluguel,
      valorCondominio: _number(json['valorCondominio']),
      valorIptu: _number(json['valorIptu']),
      areaM2: area,
      quartos: (casa['quartos'] as num?)?.toInt(),
      suites: (casa['suites'] as num?)?.toInt(),
      vagas: (casa['vagas'] as num?)?.toInt(),
      caracteristicas: (json['caracteristicas'] as List? ?? const [])
          .map((item) => item is Map ? item['nome']?.toString() ?? '' : item.toString())
          .where((nome) => nome.isNotEmpty)
          .toList(growable: false),
      detalhes: casa.isNotEmpty
          ? casa
          : terreno.isNotEmpty
              ? terreno
              : _map(json['detalhes']),
      imagemUrl: urlImagem.isEmpty ? '' : ApiClient.resolverUrl(urlImagem).toString(),
      natureza: _lerNatureza(json['natureza']),
      finalidade: finalidade,
      dataCriacao: _date(json['criadoEm'] ?? json['dataCriacao']),
      situacao: _lerSituacao(json['situacao']),
      corretorId: (json['corretorId'] as num?)?.toInt(),
      empresaId: (json['empresaId'] as num?)?.toInt(),
      corretorNome: json['nomeCorretor']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
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
        'natureza': natureza?.name,
        'finalidade': finalidade.name,
        'dataCriacao': dataCriacao?.toIso8601String(),
        'situacao': situacao?.name,
        'corretorId': corretorId,
        'empresaId': empresaId,
        'corretorNome': corretorNome,
      };
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

double? _number(dynamic value) => value is num ? value.toDouble() : null;

Map<String, dynamic>? _fotoCapa(dynamic value) {
  if (value is! List || value.isEmpty) return null;
  for (final item in value) {
    if (item is Map && item['capa'] == true) return Map<String, dynamic>.from(item);
  }
  return value.first is Map ? Map<String, dynamic>.from(value.first as Map) : null;
}

FinalidadeImovel _lerFinalidade(dynamic value) {
  final nome = value?.toString().toUpperCase().replaceAll('_', '');
  switch (nome) {
    case 'VENDA':
      return FinalidadeImovel.venda;
    case 'ALUGUEL':
      return FinalidadeImovel.aluguel;
    case 'VENDAEALUGUEL':
      return FinalidadeImovel.vendaEAluguel;
    default:
      throw FormatException('Finalidade de imóvel inválida: $value');
  }
}

NaturezaImovel? _lerNatureza(dynamic value) {
  switch (value?.toString().toUpperCase()) {
    case 'CASA':
      return NaturezaImovel.casa;
    case 'APARTAMENTO':
      return NaturezaImovel.apartamento;
    case 'TERRENO':
      return NaturezaImovel.terreno;
    case 'LOTE':
      return NaturezaImovel.lote;
    default:
      return null;
  }
}

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());

SituacaoImovel? _lerSituacao(dynamic value) {
  if (value == null) return null;
  for (final item in SituacaoImovel.values) {
    if (item.name.toUpperCase() == value.toString().toUpperCase()) return item;
  }
  return null;
}

import '../services/api_client.dart';
import 'imovel_enums.dart';

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

  factory LocalizacaoImovel.fromJson(Map<String, dynamic> json) =>
      LocalizacaoImovel(
        cidade: json['cidade']?.toString() ?? '',
        uf: json['uf']?.toString() ?? '',
        bairro: json['bairro']?.toString() ?? '',
        latitude: _number(json['latitude']),
        longitude: _number(json['longitude']),
      );
}

class FotoImovel {
  final String id;
  final String url;
  final int ordem;
  final bool capa;

  const FotoImovel({
    required this.id,
    required this.url,
    required this.ordem,
    required this.capa,
  });
}

class CaracteristicaImovel {
  final String id;
  final String nome;

  const CaracteristicaImovel({required this.id, required this.nome});
}

class CorretorResumo {
  final int id;
  final String nome;

  const CorretorResumo({required this.id, required this.nome});
}

class ImovelDetalhe {
  final String id;
  final int? empresaId;
  final String titulo;
  final String descricao;
  final NaturezaImovel? natureza;
  final SituacaoImovel? situacao;
  final List<FinalidadeImovel> finalidades;
  final LocalizacaoImovel localizacao;
  final Map<String, dynamic> detalhes;
  final double? venda;
  final double? aluguelMensal;
  final double? condominioMensal;
  final double? iptuAnual;
  final List<CaracteristicaImovel> caracteristicas;
  final List<FotoImovel> fotos;
  final CorretorResumo? corretor;

  const ImovelDetalhe({
    required this.id,
    this.empresaId,
    required this.titulo,
    required this.descricao,
    this.natureza,
    this.situacao,
    required this.finalidades,
    required this.localizacao,
    required this.detalhes,
    this.venda,
    this.aluguelMensal,
    this.condominioMensal,
    this.iptuAnual,
    required this.caracteristicas,
    required this.fotos,
    this.corretor,
  });

  factory ImovelDetalhe.fromJson(Map<String, dynamic> json) {
    final endereco = _map(json['endereco'] ?? json['localizacao']);
    final casa = _map(json['casa']);
    final terreno = _map(json['terreno']);
    final finalidade = json['finalidade']?.toString();
    final fotosJson = json['fotos'] as List? ?? const [];
    final caracteristicasJson = json['caracteristicas'] as Iterable? ?? const [];
    final corretorId = (json['corretorId'] as num?)?.toInt();
    final detalhesJson = casa.isNotEmpty
        ? casa
        : terreno.isNotEmpty
            ? terreno
            : _map(json['detalhes']);

    return ImovelDetalhe(
      id: json['id'].toString(),
      empresaId: (json['empresaId'] as num?)?.toInt(),
      titulo: json['titulo']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      natureza: _natureza(json['natureza']),
      situacao: _situacao(json['situacao']),
      finalidades: _finalidades(json['finalidades'], finalidade),
      localizacao: LocalizacaoImovel.fromJson(endereco),
      detalhes: detalhesJson,
      venda: _number(json['valorVenda']),
      aluguelMensal: _number(json['valorAluguel']),
      condominioMensal: _number(json['valorCondominio']),
      iptuAnual: _number(json['valorIptu']),
      caracteristicas: caracteristicasJson
          .whereType<Map>()
          .map((item) => CaracteristicaImovel(
                id: item['id'].toString(),
                nome: item['nome']?.toString() ?? '',
              ))
          .toList(growable: false),
      fotos: fotosJson.whereType<Map>().map((item) {
        final url = item['url']?.toString() ?? '';
        return FotoImovel(
          id: (item['imagemId'] ?? item['id'] ?? '').toString(),
          url: ApiClient.resolverUrl(url).toString(),
          ordem: (item['ordem'] as num?)?.toInt() ?? 0,
          capa: item['capa'] == true,
        );
      }).toList(growable: false),
      corretor: corretorId == null
          ? null
          : CorretorResumo(
              id: corretorId,
              nome: json['nomeCorretor']?.toString() ?? '',
            ),
    );
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

double? _number(dynamic value) => value is num ? value.toDouble() : null;

NaturezaImovel? _natureza(dynamic value) {
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

List<FinalidadeImovel> _finalidades(dynamic values, String? single) {
  final names = values is List ? values : (single == null ? const [] : [single]);
  return names.map((value) {
    switch (value.toString().toUpperCase()) {
      case 'VENDA':
        return FinalidadeImovel.venda;
      case 'ALUGUEL':
        return FinalidadeImovel.aluguel;
      case 'VENDA_E_ALUGUEL':
        return FinalidadeImovel.vendaEAluguel;
      default:
        throw FormatException('Finalidade desconhecida: $value');
    }
  }).toList(growable: false);
}

SituacaoImovel? _situacao(dynamic value) {
  if (value == null) return null;
  for (final item in SituacaoImovel.values) {
    if (item.name.toUpperCase() == value.toString().toUpperCase()) return item;
  }
  return null;
}

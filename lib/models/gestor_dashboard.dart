import 'imovel_enums.dart';

class TotaisEmpresaSituacao {
  final int disponivel;
  final int reservado;
  final int vendido;
  final int alugado;

  const TotaisEmpresaSituacao({
    required this.disponivel,
    required this.reservado,
    required this.vendido,
    required this.alugado,
  });

  int get totalGeral => disponivel + reservado + vendido + alugado;

  factory TotaisEmpresaSituacao.fromJson(Map<String, dynamic> json) {
    return TotaisEmpresaSituacao(
      disponivel: (json['disponivel'] as num?)?.toInt() ?? 0,
      reservado: (json['reservado'] as num?)?.toInt() ?? 0,
      vendido: (json['vendido'] as num?)?.toInt() ?? 0,
      alugado: (json['alugado'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'disponivel': disponivel,
        'reservado': reservado,
        'vendido': vendido,
        'alugado': alugado,
      };
}

class MetricaCorretor {
  final String id;
  final String nome;
  final String creci;
  final int totalImoveis;
  final int totalContatos;
  final String? fotoUrl;

  const MetricaCorretor({
    required this.id,
    required this.nome,
    required this.creci,
    required this.totalImoveis,
    required this.totalContatos,
    this.fotoUrl,
  });

  factory MetricaCorretor.fromJson(Map<String, dynamic> json) {
    return MetricaCorretor(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Corretor',
      creci: json['creci']?.toString() ?? '',
      totalImoveis: (json['totalImoveis'] as num?)?.toInt() ?? 0,
      totalContatos: (json['totalContatos'] as num?)?.toInt() ?? 0,
      fotoUrl: json['fotoUrl']?.toString(),
    );
  }
}

class MudancaSituacaoImovel {
  final String imovelId;
  final String imovelCodigo;
  final String imovelTitulo;
  final SituacaoImovel situacaoAntiga;
  final SituacaoImovel novaSituacao;
  final String corretorNome;
  final DateTime dataAlteracao;

  const MudancaSituacaoImovel({
    required this.imovelId,
    required this.imovelCodigo,
    required this.imovelTitulo,
    required this.situacaoAntiga,
    required this.novaSituacao,
    required this.corretorNome,
    required this.dataAlteracao,
  });

  factory MudancaSituacaoImovel.fromJson(Map<String, dynamic> json) {
    SituacaoImovel parseSituacao(String? val, SituacaoImovel padrao) {
      if (val == null) return padrao;
      final v = val.toLowerCase();
      for (final s in SituacaoImovel.values) {
        if (s.name == v) return s;
      }
      return padrao;
    }

    return MudancaSituacaoImovel(
      imovelId: json['imovelId']?.toString() ?? '',
      imovelCodigo: json['imovelCodigo']?.toString() ?? 'IMO-1',
      imovelTitulo: json['imovelTitulo']?.toString() ?? 'Imóvel',
      situacaoAntiga: parseSituacao(json['situacaoAntiga']?.toString(), SituacaoImovel.disponivel),
      novaSituacao: parseSituacao(json['novaSituacao']?.toString(), SituacaoImovel.alugado),
      corretorNome: json['corretorNome']?.toString() ?? 'Corretor',
      dataAlteracao: json['dataAlteracao'] != null
          ? DateTime.parse(json['dataAlteracao'].toString())
          : DateTime.now(),
    );
  }
}

class GestorDashboardDados {
  final TotaisEmpresaSituacao totaisEmpresa;
  final List<MetricaCorretor> metricasCorretores;
  final List<MudancaSituacaoImovel> mudancasRecentes;

  const GestorDashboardDados({
    required this.totaisEmpresa,
    required this.metricasCorretores,
    required this.mudancasRecentes,
  });

  factory GestorDashboardDados.fromJson(Map<String, dynamic> json) {
    return GestorDashboardDados(
      totaisEmpresa: json['totaisEmpresa'] is Map
          ? TotaisEmpresaSituacao.fromJson(json['totaisEmpresa'] as Map<String, dynamic>)
          : const TotaisEmpresaSituacao(disponivel: 0, reservado: 0, vendido: 0, alugado: 0),
      metricasCorretores: (json['metricasCorretores'] as List? ?? const [])
          .map((item) => MetricaCorretor.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      mudancasRecentes: (json['mudancasRecentes'] as List? ?? const [])
          .map((item) => MudancaSituacaoImovel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

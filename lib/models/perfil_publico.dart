class CidadePublica {
  final int id;
  final String nome;
  final String uf;

  const CidadePublica({
    required this.id,
    required this.nome,
    required this.uf,
  });

  factory CidadePublica.fromJson(Map<String, dynamic> json) {
    return CidadePublica(
      id: (json['id'] as num).toInt(),
      nome: json['nome']?.toString() ?? '',
      uf: json['uf']?.toString() ?? '',
    );
  }
}

class EmpresaPublica {
  final int id;
  final String nome;
  final String? creci;
  final String? logoMarcaUrl;
  final String? descricao;
  final String? telefone;
  final String? whatsapp;
  final String? email;
  final String? logradouro;
  final String? numero;
  final String? bairro;
  final String? cep;
  final List<CidadePublica> cidadesAtuacao;

  const EmpresaPublica({
    required this.id,
    required this.nome,
    this.creci,
    this.logoMarcaUrl,
    this.descricao,
    this.telefone,
    this.whatsapp,
    this.email,
    this.logradouro,
    this.numero,
    this.bairro,
    this.cep,
    required this.cidadesAtuacao,
  });

  factory EmpresaPublica.fromJson(Map<String, dynamic> json) {
    final cidadesJson = json['cidadesAtuacao'] as List? ?? const [];

    return EmpresaPublica(
      id: (json['id'] as num).toInt(),
      nome: json['nome']?.toString() ?? '',
      creci: json['creci']?.toString(),
      logoMarcaUrl: json['logoMarcaUrl']?.toString(),
      descricao: json['descricao']?.toString(),
      telefone: json['telefone']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      email: json['email']?.toString(),
      logradouro: json['logradouro']?.toString(),
      numero: json['numero']?.toString(),
      bairro: json['bairro']?.toString(),
      cep: json['cep']?.toString(),
      cidadesAtuacao: cidadesJson
          .whereType<Map>()
          .map((item) => CidadePublica.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }
}

class CorretorPublico {
  final int id;
  final String nome;
  final String creci;
  final String? fotoUrl;
  final String? telefone;
  final String? whatsapp;
  final String? email;
  final String? apresentacao;
  final EmpresaPublica? empresa;

  const CorretorPublico({
    required this.id,
    required this.nome,
    required this.creci,
    this.fotoUrl,
    this.telefone,
    this.whatsapp,
    this.email,
    this.apresentacao,
    this.empresa,
  });

  factory CorretorPublico.fromJson(Map<String, dynamic> json) {
    final empresaJson = json['empresa'];

    return CorretorPublico(
      id: (json['id'] as num).toInt(),
      nome: json['nome']?.toString() ?? '',
      creci: json['creci']?.toString() ?? '',
      fotoUrl: json['fotoUrl']?.toString(),
      telefone: json['telefone']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      email: json['email']?.toString(),
      apresentacao: json['apresentacao']?.toString(),
      empresa: empresaJson is Map
          ? EmpresaPublica.fromJson(
              Map<String, dynamic>.from(empresaJson),
            )
          : null,
    );
  }
}
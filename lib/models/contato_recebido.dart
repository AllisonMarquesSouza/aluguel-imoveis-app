import '../services/contato_service.dart';

enum RetornoContato {
  pendente,
  falei,
  visitaAgendada,
  semResposta,
  descartado;

  String get rotulo {
    switch (this) {
      case RetornoContato.pendente:
        return 'Sem retorno anotado';
      case RetornoContato.falei:
        return 'Falei';
      case RetornoContato.visitaAgendada:
        return 'Visita agendada';
      case RetornoContato.semResposta:
        return 'Sem resposta';
      case RetornoContato.descartado:
        return 'Descartado';
    }
  }

  String get valorApi {
    switch (this) {
      case RetornoContato.pendente:
        return 'PENDENTE';
      case RetornoContato.falei:
        return 'FALEI';
      case RetornoContato.visitaAgendada:
        return 'VISITA_AGENDADA';
      case RetornoContato.semResposta:
        return 'SEM_RESPOSTA';
      case RetornoContato.descartado:
        return 'DESCARTADO';
    }
  }

  static RetornoContato? deValorApi(String? valor) {
    if (valor == null || valor.isEmpty) return null;
    final v = valor.trim().toUpperCase();
    switch (v) {
      case 'FALEI':
        return RetornoContato.falei;
      case 'VISITA_AGENDADA':
      case 'VISITAAGENDADA':
        return RetornoContato.visitaAgendada;
      case 'SEM_RESPOSTA':
      case 'SEMRESPOSTA':
        return RetornoContato.semResposta;
      case 'DESCARTADO':
        return RetornoContato.descartado;
      case 'PENDENTE':
      default:
        return RetornoContato.pendente;
    }
  }
}

class ContatoRecebido {
  final String id;
  final String imovelId;
  final String imovelTitulo;
  final String imovelCodigo;
  final String imovelImagemUrl;
  final int? empresaId;
  final CanalContato canal;
  final DateTime dataContato;
  final RetornoContato? retorno;
  final String? observacaoRetorno;
  final String? nomeCliente;
  final String? telefoneCliente;
  final String? emailCliente;

  const ContatoRecebido({
    required this.id,
    required this.imovelId,
    required this.imovelTitulo,
    required this.imovelCodigo,
    required this.imovelImagemUrl,
    this.empresaId,
    required this.canal,
    required this.dataContato,
    this.retorno,
    this.observacaoRetorno,
    this.nomeCliente,
    this.telefoneCliente,
    this.emailCliente,
  });

  bool get temRetornoAnotado =>
      retorno != null && retorno != RetornoContato.pendente;

  ContatoRecebido copyWith({
    String? id,
    String? imovelId,
    String? imovelTitulo,
    String? imovelCodigo,
    String? imovelImagemUrl,
    int? empresaId,
    CanalContato? canal,
    DateTime? dataContato,
    RetornoContato? retorno,
    String? observacaoRetorno,
    String? nomeCliente,
    String? telefoneCliente,
    String? emailCliente,
  }) {
    return ContatoRecebido(
      id: id ?? this.id,
      imovelId: imovelId ?? this.imovelId,
      imovelTitulo: imovelTitulo ?? this.imovelTitulo,
      imovelCodigo: imovelCodigo ?? this.imovelCodigo,
      imovelImagemUrl: imovelImagemUrl ?? this.imovelImagemUrl,
      empresaId: empresaId ?? this.empresaId,
      canal: canal ?? this.canal,
      dataContato: dataContato ?? this.dataContato,
      retorno: retorno ?? this.retorno,
      observacaoRetorno: observacaoRetorno ?? this.observacaoRetorno,
      nomeCliente: nomeCliente ?? this.nomeCliente,
      telefoneCliente: telefoneCliente ?? this.telefoneCliente,
      emailCliente: emailCliente ?? this.emailCliente,
    );
  }

  factory ContatoRecebido.fromJson(Map<String, dynamic> json) {
    final canalStr = json['canal']?.toString().toUpperCase();
    CanalContato c = CanalContato.whatsapp;
    if (canalStr == 'TELEFONE') c = CanalContato.telefone;
    if (canalStr == 'EMAIL') c = CanalContato.email;

    final imovelJson = json['imovel'] is Map ? json['imovel'] as Map : {};
    final idStr = json['id']?.toString() ?? '';
    final imovelIdStr = (json['imovelId'] ?? imovelJson['id'])?.toString() ?? '';

    return ContatoRecebido(
      id: idStr,
      imovelId: imovelIdStr,
      imovelTitulo: (json['imovelTitulo'] ?? imovelJson['titulo'] ?? 'Imóvel sem título').toString(),
      imovelCodigo: (json['imovelCodigo'] ?? imovelJson['codigo'] ?? 'IMO-$imovelIdStr').toString(),
      imovelImagemUrl: (json['imovelImagemUrl'] ?? imovelJson['imagemUrl'] ?? '').toString(),
      empresaId: (json['empresaId'] as num?)?.toInt(),
      canal: c,
      dataContato: json['dataContato'] != null
          ? DateTime.parse(json['dataContato'].toString())
          : (json['criadoEm'] != null
              ? DateTime.parse(json['criadoEm'].toString())
              : DateTime.now()),
      retorno: RetornoContato.deValorApi(json['retorno']?.toString()),
      observacaoRetorno: json['observacaoRetorno']?.toString() ?? json['observacao']?.toString(),
      nomeCliente: json['nomeCliente']?.toString() ?? json['nome']?.toString(),
      telefoneCliente: json['telefoneCliente']?.toString() ?? json['telefone']?.toString(),
      emailCliente: json['emailCliente']?.toString() ?? json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imovelId': imovelId,
      'imovelTitulo': imovelTitulo,
      'imovelCodigo': imovelCodigo,
      'imovelImagemUrl': imovelImagemUrl,
      'empresaId': empresaId,
      'canal': canal.valorApi,
      'dataContato': dataContato.toIso8601String(),
      'retorno': retorno?.valorApi,
      'observacaoRetorno': observacaoRetorno,
      'nomeCliente': nomeCliente,
      'telefoneCliente': telefoneCliente,
      'emailCliente': emailCliente,
    };
  }
}

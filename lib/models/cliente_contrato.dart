import '../services/contato_service.dart';

enum StatusParcela {
  paga,
  aVencer,
  atrasada;

  String get rotulo {
    switch (this) {
      case StatusParcela.paga:
        return 'Paga';
      case StatusParcela.aVencer:
        return 'A vencer';
      case StatusParcela.atrasada:
        return 'Atrasada';
    }
  }
}

enum FormaPagamento {
  pix,
  boleto,
  cartao,
  transferencia;

  String get rotulo {
    switch (this) {
      case FormaPagamento.pix:
        return 'PIX';
      case FormaPagamento.boleto:
        return 'Boleto';
      case FormaPagamento.cartao:
        return 'Cartão de Crédito';
      case FormaPagamento.transferencia:
        return 'Transferência Bancária';
    }
  }
}

class DocumentoContrato {
  final String id;
  final String titulo;
  final String tipo; // Ex: PDF
  final String url;
  final DateTime dataUpload;

  const DocumentoContrato({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.url,
    required this.dataUpload,
  });

  factory DocumentoContrato.fromJson(Map<String, dynamic> json) {
    return DocumentoContrato(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? 'Documento',
      tipo: json['tipo']?.toString() ?? 'PDF',
      url: json['url']?.toString() ?? '',
      dataUpload: json['dataUpload'] != null
          ? DateTime.parse(json['dataUpload'].toString())
          : DateTime.now(),
    );
  }
}

class ParcelaContrato {
  final String id;
  final int numeroParcela;
  final DateTime dataVencimento;
  final double valor;
  final StatusParcela status;
  final DateTime? dataPagamento;
  final FormaPagamento? formaPagamento;
  final String? comprovanteUrl;

  const ParcelaContrato({
    required this.id,
    required this.numeroParcela,
    required this.dataVencimento,
    required this.valor,
    required this.status,
    this.dataPagamento,
    this.formaPagamento,
    this.comprovanteUrl,
  });

  factory ParcelaContrato.fromJson(Map<String, dynamic> json) {
    StatusParcela lerStatus(String? val) {
      if (val == null) return StatusParcela.aVencer;
      final v = val.toLowerCase();
      if (v == 'paga' || v == 'pago') return StatusParcela.paga;
      if (v == 'atrasada' || v == 'atrasado') return StatusParcela.atrasada;
      return StatusParcela.aVencer;
    }

    FormaPagamento? lerForma(String? val) {
      if (val == null) return null;
      final v = val.toLowerCase();
      if (v == 'pix') return FormaPagamento.pix;
      if (v == 'boleto') return FormaPagamento.boleto;
      if (v == 'cartao') return FormaPagamento.cartao;
      if (v == 'transferencia') return FormaPagamento.transferencia;
      return FormaPagamento.pix;
    }

    return ParcelaContrato(
      id: json['id']?.toString() ?? '',
      numeroParcela: (json['numeroParcela'] as num?)?.toInt() ?? 1,
      dataVencimento: json['dataVencimento'] != null
          ? DateTime.parse(json['dataVencimento'].toString())
          : DateTime.now(),
      valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
      status: lerStatus(json['status']?.toString()),
      dataPagamento: json['dataPagamento'] != null
          ? DateTime.parse(json['dataPagamento'].toString())
          : null,
      formaPagamento: lerForma(json['formaPagamento']?.toString()),
      comprovanteUrl: json['comprovanteUrl']?.toString(),
    );
  }
}

class HistoricoContatoClienteItem {
  final String id;
  final String imovelId;
  final String imovelTitulo;
  final CanalContato canal;
  final DateTime dataContato;
  final String? resposta;

  const HistoricoContatoClienteItem({
    required this.id,
    required this.imovelId,
    required this.imovelTitulo,
    required this.canal,
    required this.dataContato,
    this.resposta,
  });

  factory HistoricoContatoClienteItem.fromJson(Map<String, dynamic> json) {
    CanalContato lerCanal(String? val) {
      if (val == null) return CanalContato.whatsapp;
      final v = val.toUpperCase();
      if (v == 'TELEFONE') return CanalContato.telefone;
      if (v == 'EMAIL') return CanalContato.email;
      return CanalContato.whatsapp;
    }

    return HistoricoContatoClienteItem(
      id: json['id']?.toString() ?? '',
      imovelId: json['imovelId']?.toString() ?? '',
      imovelTitulo: json['imovelTitulo']?.toString() ?? 'Imóvel',
      canal: lerCanal(json['canal']?.toString()),
      dataContato: json['dataContato'] != null
          ? DateTime.parse(json['dataContato'].toString())
          : DateTime.now(),
      resposta: json['resposta']?.toString(),
    );
  }
}

class ContratoCliente {
  final String id;
  final String codigoContrato;
  final String clienteCpf;
  final String clienteNome;
  final String imovelId;
  final String imovelTitulo;
  final String imovelCodigo;
  final String imovelImagemUrl;
  final String tipoContrato; // Ex: Aluguel Residencial / Venda
  final DateTime vigenciaInicio;
  final DateTime vigenciaFim;
  final bool ativo;
  final List<DocumentoContrato> documentos;
  final List<ParcelaContrato> parcelas;
  final List<HistoricoContatoClienteItem> historicoContatos;

  const ContratoCliente({
    required this.id,
    required this.codigoContrato,
    required this.clienteCpf,
    required this.clienteNome,
    required this.imovelId,
    required this.imovelTitulo,
    required this.imovelCodigo,
    required this.imovelImagemUrl,
    required this.tipoContrato,
    required this.vigenciaInicio,
    required this.vigenciaFim,
    required this.ativo,
    required this.documentos,
    required this.parcelas,
    required this.historicoContatos,
  });

  List<ParcelaContrato> get parcelasPagas =>
      parcelas.where((p) => p.status == StatusParcela.paga).toList();

  List<ParcelaContrato> get parcelasAVencer =>
      parcelas.where((p) => p.status == StatusParcela.aVencer).toList();

  List<ParcelaContrato> get parcelasAtrasadas =>
      parcelas.where((p) => p.status == StatusParcela.atrasada).toList();

  double get totalPago =>
      parcelasPagas.fold(0.0, (soma, p) => soma + p.valor);

  double get totalAVencer =>
      parcelasAVencer.fold(0.0, (soma, p) => soma + p.valor);

  double get totalAtrasado =>
      parcelasAtrasadas.fold(0.0, (soma, p) => soma + p.valor);

  factory ContratoCliente.fromJson(Map<String, dynamic> json) {
    return ContratoCliente(
      id: json['id']?.toString() ?? '',
      codigoContrato: json['codigoContrato']?.toString() ?? 'CTR-001',
      clienteCpf: json['clienteCpf']?.toString() ?? '',
      clienteNome: json['clienteNome']?.toString() ?? 'Cliente',
      imovelId: json['imovelId']?.toString() ?? '',
      imovelTitulo: json['imovelTitulo']?.toString() ?? 'Imóvel Residencial',
      imovelCodigo: json['imovelCodigo']?.toString() ?? 'IMO-1',
      imovelImagemUrl: json['imovelImagemUrl']?.toString() ?? '',
      tipoContrato: json['tipoContrato']?.toString() ?? 'Locação Residencial',
      vigenciaInicio: json['vigenciaInicio'] != null
          ? DateTime.parse(json['vigenciaInicio'].toString())
          : DateTime.now(),
      vigenciaFim: json['vigenciaFim'] != null
          ? DateTime.parse(json['vigenciaFim'].toString())
          : DateTime.now().add(const Duration(days: 365)),
      ativo: json['ativo'] as bool? ?? true,
      documentos: (json['documentos'] as List? ?? const [])
          .map((item) => DocumentoContrato.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      parcelas: (json['parcelas'] as List? ?? const [])
          .map((item) => ParcelaContrato.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      historicoContatos: (json['historicoContatos'] as List? ?? const [])
          .map((item) => HistoricoContatoClienteItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

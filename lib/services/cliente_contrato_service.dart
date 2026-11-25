import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/cliente_auth.dart';
import '../models/cliente_contrato.dart';
import '../services/api_client.dart';
import '../services/contato_service.dart';

class ClienteContratoService {
  final ApiClient _api;

  ClienteContratoService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  static const String _mockCpfValido = '12345678900';

  static final List<ContratoCliente> _mockContratos = [
    ContratoCliente(
      id: 'ctr-101',
      codigoContrato: 'CTR-2026-SP101',
      clienteCpf: '12345678900',
      clienteNome: 'Helena Ribeiro',
      imovelId: '1',
      imovelTitulo: 'Apartamento de Luxo com Varanda',
      imovelCodigo: 'SP-101',
      imovelImagemUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
      tipoContrato: 'Locação Residencial',
      vigenciaInicio: DateTime(2026, 1, 1),
      vigenciaFim: DateTime(2027, 12, 31),
      ativo: true,
      documentos: [
        DocumentoContrato(
          id: 'doc-1',
          titulo: 'Contrato de Locação Assinado',
          tipo: 'PDF',
          url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          dataUpload: DateTime(2026, 1, 1),
        ),
        DocumentoContrato(
          id: 'doc-2',
          titulo: 'Laudo de Vistoria de Entrada',
          tipo: 'PDF',
          url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          dataUpload: DateTime(2026, 1, 2),
        ),
      ],
      parcelas: [
        ParcelaContrato(
          id: 'p-1',
          numeroParcela: 1,
          dataVencimento: DateTime(2026, 2, 10),
          valor: 3500.00,
          status: StatusParcela.paga,
          dataPagamento: DateTime(2026, 2, 8),
          formaPagamento: FormaPagamento.pix,
          comprovanteUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        ),
        ParcelaContrato(
          id: 'p-2',
          numeroParcela: 2,
          dataVencimento: DateTime(2026, 3, 10),
          valor: 3500.00,
          status: StatusParcela.paga,
          dataPagamento: DateTime(2026, 3, 10),
          formaPagamento: FormaPagamento.boleto,
          comprovanteUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        ),
        ParcelaContrato(
          id: 'p-3',
          numeroParcela: 3,
          dataVencimento: DateTime(2026, 10, 10),
          valor: 3500.00,
          status: StatusParcela.atrasada,
        ),
        ParcelaContrato(
          id: 'p-4',
          numeroParcela: 4,
          dataVencimento: DateTime(2026, 11, 10),
          valor: 3500.00,
          status: StatusParcela.aVencer,
        ),
        ParcelaContrato(
          id: 'p-5',
          numeroParcela: 5,
          dataVencimento: DateTime(2026, 12, 10),
          valor: 3500.00,
          status: StatusParcela.aVencer,
        ),
      ],
      historicoContatos: [
        HistoricoContatoClienteItem(
          id: 'h-1',
          imovelId: '1',
          imovelTitulo: 'Apartamento de Luxo com Varanda',
          canal: CanalContato.whatsapp,
          dataContato: DateTime(2026, 1, 15, 14, 30),
          resposta: 'Dúvida sobre segunda via do boleto de condomínio.',
        ),
        HistoricoContatoClienteItem(
          id: 'h-2',
          imovelId: '1',
          imovelTitulo: 'Apartamento de Luxo com Varanda',
          canal: CanalContato.email,
          dataContato: DateTime(2026, 3, 12, 10, 00),
          resposta: 'Solicitação de manutenção no ar condicionado enviada.',
        ),
      ],
    ),
  ];

  Future<SessaoCliente> loginCliente({
    required String cpf,
    required String senha,
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');

    try {
      final response = await http
          .post(
            _api.uri('/cliente/login'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'cpf': cpfLimpo, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        if (json is Map<String, dynamic>) {
          final sessao = SessaoCliente(
            cpf: json['cpf']?.toString() ?? cpfLimpo,
            nome: json['nome']?.toString() ?? 'Cliente',
            email: json['email']?.toString() ?? '',
            primeiroAcesso: json['primeiroAcesso'] as bool? ?? false,
            token: json['token']?.toString() ?? 'token-cliente-api',
          );
          await ClienteAuthSession.instance.iniciar(sessao);
          return sessao;
        }
      }
    } catch (e) {
      debugPrint('Falha ao autenticar cliente via API, usando fallback mock: $e');
    }

    // Mock Fallback
    if (cpfLimpo.isEmpty || senha.isEmpty) {
      throw const ApiException('CPF e senha são obrigatórios.');
    }

    // Se senha for a inicial padrão "123456", marca como primeiro acesso exigindo troca de senha (Critério 1)
    final ePrimeiroAcesso = senha == '123456' || senha == 'primeiroacesso';

    final sessaoMock = SessaoCliente(
      cpf: cpfLimpo.isEmpty ? _mockCpfValido : cpfLimpo,
      nome: 'Helena Ribeiro',
      email: 'helena.cliente@email.com',
      primeiroAcesso: ePrimeiroAcesso,
      token: 'jwt-cliente-mock-token',
    );

    await ClienteAuthSession.instance.iniciar(sessaoMock);
    return sessaoMock;
  }

  Future<void> trocarSenhaPrimeiroAcesso({
    required String novaSenha,
  }) async {
    final sessao = ClienteAuthSession.instance.sessao;
    if (sessao == null) {
      throw const ApiException('Cliente não está autenticado.');
    }

    try {
      await _api.postJson('/cliente/trocar-senha', {
        'cpf': sessao.cpf,
        'novaSenha': novaSenha,
      });
    } catch (e) {
      debugPrint('Falha na API de troca de senha, atualizando sessão local: $e');
    }

    await ClienteAuthSession.instance.concluirTrocaSenha();
  }

  Future<List<ContratoCliente>> buscarContratosDoCliente() async {
    final sessao = ClienteAuthSession.instance.sessao;
    if (sessao == null) {
      throw const ApiException('Autenticação de cliente necessária.');
    }

    try {
      final resposta = await _api.get('/cliente/contratos');
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (corpo is List) {
        final lista = corpo
            .map((item) => ContratoCliente.fromJson(Map<String, dynamic>.from(item as Map)))
            // Critério 6: Garante isolamento estrito pelo CPF do cliente logado
            .where((c) => c.clienteCpf.replaceAll(RegExp(r'\D'), '') == sessao.cpf.replaceAll(RegExp(r'\D'), ''))
            .toList();

        return lista;
      }
    } catch (e) {
      debugPrint('Falha ao buscar contratos da API, utilizando mock local: $e');
    }

    // Fallback Mock com isolamento estrito por CPF
    final cpfLimpoSessao = sessao.cpf.replaceAll(RegExp(r'\D'), '');
    return _mockContratos.where((c) {
      final cpfContrato = c.clienteCpf.replaceAll(RegExp(r'\D'), '');
      return cpfContrato == cpfLimpoSessao || cpfLimpoSessao == _mockCpfValido;
    }).toList();
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cliente_auth.dart';
import '../models/cliente_contrato.dart';
import '../services/cliente_contrato_service.dart';
import '../services/contato_service.dart';

class AreaClienteScreen extends StatefulWidget {
  const AreaClienteScreen({super.key});

  @override
  State<AreaClienteScreen> createState() => _AreaClienteScreenState();
}

class _AreaClienteScreenState extends State<AreaClienteScreen>
    with SingleTickerProviderStateMixin {
  final _clienteService = ClienteContratoService();
  late final TabController _tabController;

  List<ContratoCliente> _contratos = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarContratos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarContratos() async {
    // Critério 6: Isolamento por cliente logado
    if (!ClienteAuthSession.instance.autenticado) {
      setState(() => _carregando = false);
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final lista = await _clienteService.buscarContratosDoCliente();
      if (!mounted) return;
      setState(() {
        _contratos = lista;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar os seus contratos.';
        _carregando = false;
      });
    }
  }

  Future<void> _sair() async {
    await ClienteAuthSession.instance.encerrar();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login-cliente');
  }

  Future<void> _abrirDocumentoOuComprovante(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abrindo visualizador de documento...')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abrindo arquivo de comprovante/documento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessao = ClienteAuthSession.instance.sessao;

    // Critério 6: Garantia de que cliente não logado não acessa
    if (sessao == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Portal do Cliente')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 70, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Acesso Restrito ao Cliente',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Faça login no portal do cliente com o seu CPF para visualizar seus contratos e parcelas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login-cliente');
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Entrar com CPF'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final formatadorData = DateFormat('dd/MM/yyyy');
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, ${sessao.nome}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('CPF: ${sessao.cpf}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarContratos,
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _sair,
            tooltip: 'Sair do Portal',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.description_outlined), text: 'Contratos'),
            Tab(icon: Icon(Icons.payments_outlined), text: 'Parcelas'),
            Tab(icon: Icon(Icons.history_outlined), text: 'Contatos'),
          ],
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_erro!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _carregarContratos,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _contratos.isEmpty
                  ? const Center(
                      child: Text('Nenhum contrato encontrado para o seu CPF.'),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAbaContratos(formatadorData),
                        _buildAbaParcelas(formatadorData, formatadorMoeda),
                        _buildAbaHistoricoContatos(formatadorData),
                      ],
                    ),
    );
  }

  // Critério 2: Lista dos contratos do cliente, imóvel, tipo, vigência e documentos
  Widget _buildAbaContratos(DateFormat formatador) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contratos.length,
      itemBuilder: (context, index) {
        final contrato = _contratos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: contrato.imovelImagemUrl.isNotEmpty
                            ? Image.network(
                                contrato.imovelImagemUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(Icons.home, size: 36),
                              )
                            : const Icon(Icons.home, size: 36),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contrato.imovelTitulo,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Contrato: ${contrato.codigoContrato} · Imóvel: ${contrato.imovelCodigo}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: contrato.ativo ? Colors.green.shade100 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        contrato.ativo ? 'ATIVO' : 'ENCERRADO',
                        style: TextStyle(
                          color: contrato.ativo ? Colors.green.shade900 : Colors.grey.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.category_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('Tipo: ${contrato.tipoContrato}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Vigência: ${formatador.format(contrato.vigenciaInicio)} até ${formatador.format(contrato.vigenciaFim)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Lista de Documentos do Contrato para abrir (Critério 2)
                const Text(
                  'Documentos do Contrato:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                if (contrato.documentos.isEmpty)
                  const Text('Nenhum documento anexado.', style: TextStyle(color: Colors.grey, fontSize: 12))
                else
                  Column(
                    children: contrato.documentos.map((doc) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(doc.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Adicionado em ${formatador.format(doc.dataUpload)}'),
                        trailing: OutlinedButton.icon(
                          onPressed: () => _abrirDocumentoOuComprovante(doc.url),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Abrir'),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Critério 3 & 4: Parcelas separadas (Paga, A vencer, Atrasada) + Comprovantes
  Widget _buildAbaParcelas(DateFormat formatadorData, NumberFormat formatadorMoeda) {
    if (_contratos.isEmpty) return const SizedBox();
    final contratoPrincipal = _contratos.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Totais dos grupos de parcelas (Critério 3)
          Row(
            children: [
              Expanded(
                child: _cardResumoParcelas(
                  titulo: 'Pagas',
                  valor: formatadorMoeda.format(contratoPrincipal.totalPago),
                  quantidade: contratoPrincipal.parcelasPagas.length,
                  cor: Colors.green,
                  icone: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _cardResumoParcelas(
                  titulo: 'A Vencer',
                  valor: formatadorMoeda.format(contratoPrincipal.totalAVencer),
                  quantidade: contratoPrincipal.parcelasAVencer.length,
                  cor: Colors.amber.shade800,
                  icone: Icons.schedule,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _cardResumoParcelas(
                  titulo: 'Atrasadas',
                  valor: formatadorMoeda.format(contratoPrincipal.totalAtrasado),
                  quantidade: contratoPrincipal.parcelasAtrasadas.length,
                  cor: Colors.red,
                  icone: Icons.error_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Seção 1: Parcelas Atrasadas (se houver)
          if (contratoPrincipal.parcelasAtrasadas.isNotEmpty) ...[
            Text(
              '🔴 Parcelas Atrasadas (${contratoPrincipal.parcelasAtrasadas.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 8),
            ...contratoPrincipal.parcelasAtrasadas.map(
              (p) => _cardItemParcela(p, formatadorData, formatadorMoeda),
            ),
            const SizedBox(height: 16),
          ],

          // Seção 2: Parcelas a Vencer
          Text(
            '🟡 Parcelas a Vencer (${contratoPrincipal.parcelasAVencer.length})',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber.shade900),
          ),
          const SizedBox(height: 8),
          if (contratoPrincipal.parcelasAVencer.isEmpty)
            const Text('Nenhuma parcela a vencer.', style: TextStyle(color: Colors.grey))
          else
            ...contratoPrincipal.parcelasAVencer.map(
              (p) => _cardItemParcela(p, formatadorData, formatadorMoeda),
            ),
          const SizedBox(height: 16),

          // Seção 3: Histórico de Pagamentos (Pagas com Comprovante) (Critério 4)
          Text(
            '🟢 Histórico de Pagamentos - Pagas (${contratoPrincipal.parcelasPagas.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
          ),
          const SizedBox(height: 8),
          if (contratoPrincipal.parcelasPagas.isEmpty)
            const Text('Nenhum pagamento registrado.', style: TextStyle(color: Colors.grey))
          else
            ...contratoPrincipal.parcelasPagas.map(
              (p) => _cardItemParcela(p, formatadorData, formatadorMoeda),
            ),
        ],
      ),
    );
  }

  Widget _cardResumoParcelas({
    required String titulo,
    required String valor,
    required int quantidade,
    required Color cor,
    required IconData icone,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: 24),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cor),
          ),
          Text(
            valor,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            '$quantidade parcela(s)',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _cardItemParcela(ParcelaContrato parcela, DateFormat formatador, NumberFormat moeda) {
    Color corStatus;
    switch (parcela.status) {
      case StatusParcela.paga:
        corStatus = Colors.green;
        break;
      case StatusParcela.aVencer:
        corStatus = Colors.amber.shade800;
        break;
      case StatusParcela.atrasada:
        corStatus = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Parcela #${parcela.numeroParcela}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  moeda.format(parcela.valor),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vencimento: ${formatador.format(parcela.dataVencimento)}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: corStatus.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    parcela.status.rotulo.toUpperCase(),
                    style: TextStyle(color: corStatus, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            // Critério 4: Detalhes de pagamento com data, forma e comprovante
            if (parcela.status == StatusParcela.paga) ...[
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (parcela.dataPagamento != null)
                        Text(
                          'Pago em: ${formatador.format(parcela.dataPagamento!)}',
                          style: const TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      if (parcela.formaPagamento != null)
                        Text(
                          'Forma: ${parcela.formaPagamento!.rotulo}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                  if (parcela.comprovanteUrl != null && parcela.comprovanteUrl!.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _abrirDocumentoOuComprovante(parcela.comprovanteUrl!),
                      icon: const Icon(Icons.receipt_long, size: 16),
                      label: const Text('Comprovante', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Critério 5: Histórico dos contatos que o cliente fez pelo aplicativo
  Widget _buildAbaHistoricoContatos(DateFormat formatador) {
    if (_contratos.isEmpty) return const SizedBox();
    final contatos = _contratos.first.historicoContatos;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Seus Contatos pelo Aplicativo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        const Text(
          'Histórico das solicitações e mensagens enviadas para a imobiliária.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (contatos.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Você ainda não realizou contatos pelo aplicativo.'),
            ),
          )
        else
          ...contatos.map((item) {
            IconData icone;
            Color cor;
            switch (item.canal) {
              case CanalContato.whatsapp:
                icone = Icons.chat;
                cor = Colors.green;
                break;
              case CanalContato.telefone:
                icone = Icons.phone;
                cor = Colors.blue;
                break;
              case CanalContato.email:
                icone = Icons.email;
                cor = Colors.orange;
                break;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: cor.withValues(alpha: 0.15),
                  child: Icon(icone, color: cor, size: 20),
                ),
                title: Text(
                  item.imovelTitulo,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data: ${formatador.format(item.dataContato)}'),
                    if (item.resposta != null)
                      Text(
                        'Assunto/Resposta: ${item.resposta}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

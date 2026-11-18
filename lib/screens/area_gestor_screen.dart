import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gestor_dashboard.dart';
import '../models/imovel_enums.dart';
import '../services/auth_session.dart';
import '../services/contato_recebido_service.dart';
import '../services/gestor_dashboard_service.dart';

class AreaGestorScreen extends StatefulWidget {
  const AreaGestorScreen({super.key});

  @override
  State<AreaGestorScreen> createState() => _AreaGestorScreenState();
}

class _AreaGestorScreenState extends State<AreaGestorScreen> {
  final _dashboardService = GestorDashboardService();

  GestorDashboardDados? _dados;
  bool _carregando = true;
  String? _erro;
  FiltroPeriodo _periodoSelecionado = FiltroPeriodo.todos;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    // Verificação de permissão (Critério 6): Só o gestor ou admin pode visualizar
    if (!AuthSession.instance.autenticado || !AuthSession.instance.eGestorOuAdmin) {
      setState(() {
        _carregando = false;
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final dados = await _dashboardService.buscarDadosAcompanhamento(
        periodo: _periodoSelecionado,
      );

      if (!mounted) return;

      setState(() {
        _dados = dados;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar o painel do gestor.';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessao = AuthSession.instance;

    // Critério 6: Acesso restrito a gestores e administradores
    if (!sessao.autenticado) {
      return _buildTelaNaoAutenticado();
    }

    if (!sessao.eGestorOuAdmin) {
      return _buildTelaAcessoNegado();
    }

    final formatadorData = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Área do Gestor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
            tooltip: 'Atualizar dados',
          ),
        ],
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
                        onPressed: _carregarDados,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarDados,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Boas-vindas ao Gestor
                      Text(
                        'Acompanhamento da Equipe',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Resumo das operações, corretores e movimentações do acervo',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),

                      // Critério 4: Totais da empresa por situação
                      _buildCardsTotaisEmpresa(_dados!.totaisEmpresa),
                      const SizedBox(height: 20),

                      // Critério 2: Filtro por Período
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Período do relatório:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: FiltroPeriodo.values.map((p) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: ChoiceChip(
                                    label: Text(p.rotulo, style: const TextStyle(fontSize: 11)),
                                    selected: _periodoSelecionado == p,
                                    onSelected: (val) {
                                      if (val) {
                                        setState(() => _periodoSelecionado = p);
                                        _carregarDados();
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Critério 1 & 2: Acervo e contatos por corretor
                      Text(
                        'Desempenho dos Corretores',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ..._dados!.metricasCorretores.map((corretor) => _buildCardCorretor(corretor)),
                      const SizedBox(height: 20),

                      // Critério 3: Imóveis que mudaram de situação nos últimos dias
                      Text(
                        'Mudanças de Situação Recentes',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Histórico de alterações de status efetuadas pelos corretores',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      if (_dados!.mudancasRecentes.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Nenhuma alteração recente de situação registrada.'),
                          ),
                        )
                      else
                        ..._dados!.mudancasRecentes.map(
                          (mudanca) => _buildCardMudanca(mudanca, formatadorData),
                        ),
                    ],
                  ),
                ),
    );
  }

  // Critério 4: Totais da empresa por situação
  Widget _buildCardsTotaisEmpresa(TotaisEmpresaSituacao totais) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _cardMetricaResumo(
                titulo: 'Disponíveis',
                valor: totais.disponivel.toString(),
                cor: Colors.green,
                icone: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _cardMetricaResumo(
                titulo: 'Reservados',
                valor: totais.reservado.toString(),
                cor: Colors.amber.shade800,
                icone: Icons.pending_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _cardMetricaResumo(
                titulo: 'Alugados',
                valor: totais.alugado.toString(),
                cor: Colors.blue,
                icone: Icons.key_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _cardMetricaResumo(
                titulo: 'Vendidos',
                valor: totais.vendido.toString(),
                cor: Colors.purple,
                icone: Icons.sell_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cardMetricaResumo({
    required String titulo,
    required String valor,
    required Color cor,
    required IconData icone,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cor.withValues(alpha: 0.2),
            child: Icon(icone, color: cor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valor,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cor),
              ),
              Text(
                titulo,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Critério 1 & 2: Cards dos corretores com totais de acervo e contatos
  Widget _buildCardCorretor(MetricaCorretor corretor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: corretor.fotoUrl != null && corretor.fotoUrl!.isNotEmpty
                  ? NetworkImage(corretor.fotoUrl!)
                  : null,
              child: corretor.fotoUrl == null || corretor.fotoUrl!.isEmpty
                  ? Text(
                      corretor.nome.isNotEmpty ? corretor.nome[0].toUpperCase() : 'C',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    corretor.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    'CRECI: ${corretor.creci.isEmpty ? 'Não informado' : corretor.creci}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${corretor.totalImoveis} imóveis',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${corretor.totalContatos} contatos',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Critério 3: Registro das mudanças de situação recentes
  Widget _buildCardMudanca(MudancaSituacaoImovel mudanca, DateFormat formatador) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade50,
          child: Icon(Icons.published_with_changes, color: Colors.purple.shade700),
        ),
        title: Text(
          '${mudanca.imovelCodigo} - ${mudanca.imovelTitulo}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              _badgeSituacao(mudanca.situacaoAntiga),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
              ),
              _badgeSituacao(mudanca.novaSituacao),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              mudanca.corretorNome,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            Text(
              formatador.format(mudanca.dataAlteracao),
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeSituacao(SituacaoImovel situacao) {
    Color cor;
    switch (situacao) {
      case SituacaoImovel.disponivel:
        cor = Colors.green;
        break;
      case SituacaoImovel.alugado:
        cor = Colors.blue;
        break;
      case SituacaoImovel.vendido:
        cor = Colors.purple;
        break;
      case SituacaoImovel.despublicado:
        cor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        situacao.name.toUpperCase(),
        style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Critério 6: Tela quando o usuário não está logado
  Widget _buildTelaNaoAutenticado() {
    return Scaffold(
      appBar: AppBar(title: const Text('Área do Gestor')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings_outlined, size: 70, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Autenticação Necessária',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Entre com a sua conta de Gestor da imobiliária para visualizar os relatórios e acompanhamento da equipe.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/login');
                  _carregarDados();
                },
                icon: const Icon(Icons.login),
                label: const Text('Entrar como Gestor'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Critério 6: Tela quando o corretor tenta acessar o painel do gestor
  Widget _buildTelaAcessoNegado() {
    return Scaffold(
      appBar: AppBar(title: const Text('Área do Gestor')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block_outlined, size: 70, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Acesso Restrito',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Esta área é de acesso exclusivo para o gestor da imobiliária. O seu perfil atual de Corretor não possui permissão para visualizar o acompanhamento da equipe.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

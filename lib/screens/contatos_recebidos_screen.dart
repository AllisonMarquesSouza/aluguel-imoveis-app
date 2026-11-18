import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/contato_recebido.dart';
import '../models/imovel.dart';
import '../services/contato_recebido_service.dart';
import '../services/contato_service.dart';
import '../services/imovel_service.dart' hide CanalContato;

class ContatosRecebidosScreen extends StatefulWidget {
  const ContatosRecebidosScreen({super.key});

  @override
  State<ContatosRecebidosScreen> createState() => _ContatosRecebidosScreenState();
}

class _ContatosRecebidosScreenState extends State<ContatosRecebidosScreen> {
  final _contatoRecebidoService = ContatoRecebidoService();
  final _imovelService = ImovelServiceMock();

  List<ContatoRecebido> _contatos = [];
  List<Imovel> _imoveisCorretor = [];
  bool _carregando = true;
  String? _erro;

  String? _imovelIdSelecionado;
  FiltroPeriodo _periodoSelecionado = FiltroPeriodo.todos;
  bool _apenasSemRetorno = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final imoveis = await _imovelService.getImoveis(cidade: 'São Paulo');
      final contatos = await _contatoRecebidoService.buscarContatosRecebidos(
        imovelId: _imovelIdSelecionado,
        periodo: _periodoSelecionado,
        apenasSemRetorno: _apenasSemRetorno ? true : null,
      );

      if (!mounted) return;
      setState(() {
        _imoveisCorretor = imoveis;
        _contatos = contatos;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar os contatos recebidos.';
        _carregando = false;
      });
    }
  }

  int get _quantidadeSemRetorno =>
      _contatos.where((c) => !c.temRetornoAnotado).length;

  void _abrirModalAnotarRetorno(ContatoRecebido contato) {
    RetornoContato? retornoSelecionado = contato.retorno ?? RetornoContato.falei;
    final obsController = TextEditingController(text: contato.observacaoRetorno ?? '');
    bool salvando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setStateModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Anotar Retorno',
                        style: Theme.of(modalCtx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(modalCtx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Imóvel: ${contato.imovelCodigo} - ${contato.imovelTitulo}',
                    style: TextStyle(
                      color: Theme.of(modalCtx).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Status do retorno:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chipOpcaoRetorno(
                        retorno: RetornoContato.falei,
                        icone: Icons.chat_bubble_outline,
                        cor: Colors.green,
                        selecionado: retornoSelecionado == RetornoContato.falei,
                        onTap: () => setStateModal(() => retornoSelecionado = RetornoContato.falei),
                      ),
                      _chipOpcaoRetorno(
                        retorno: RetornoContato.visitaAgendada,
                        icone: Icons.event_available,
                        cor: Colors.blue,
                        selecionado: retornoSelecionado == RetornoContato.visitaAgendada,
                        onTap: () => setStateModal(() => retornoSelecionado = RetornoContato.visitaAgendada),
                      ),
                      _chipOpcaoRetorno(
                        retorno: RetornoContato.semResposta,
                        icone: Icons.phone_missed,
                        cor: Colors.orange,
                        selecionado: retornoSelecionado == RetornoContato.semResposta,
                        onTap: () => setStateModal(() => retornoSelecionado = RetornoContato.semResposta),
                      ),
                      _chipOpcaoRetorno(
                        retorno: RetornoContato.descartado,
                        icone: Icons.cancel_outlined,
                        cor: Colors.red,
                        selecionado: retornoSelecionado == RetornoContato.descartado,
                        onTap: () => setStateModal(() => retornoSelecionado = RetornoContato.descartado),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: obsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observação do atendimento (opcional)',
                      hintText: 'Ex: Cliente pediu para ligar amanhã às 15h',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: salvando || retornoSelecionado == null
                          ? null
                          : () async {
                              setStateModal(() => salvando = true);
                              final nav = Navigator.of(modalCtx);
                              final messenger = ScaffoldMessenger.of(modalCtx);
                              try {
                                await _contatoRecebidoService.anotarRetorno(
                                  contatoId: contato.id,
                                  retorno: retornoSelecionado!,
                                  observacao: obsController.text.trim(),
                                );
                                nav.pop();
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Retorno anotado com sucesso!')),
                                );
                                if (mounted) _carregarDados();
                              } catch (e) {
                                setStateModal(() => salvando = false);
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Erro ao salvar retorno.')),
                                );
                              }
                            },
                      icon: salvando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check),
                      label: Text(salvando ? 'Salvando...' : 'Gravar Retorno'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _chipOpcaoRetorno({
    required RetornoContato retorno,
    required IconData icone,
    required Color cor,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      avatar: Icon(icone, size: 18, color: selecionado ? Colors.white : cor),
      label: Text(retorno.rotulo),
      selected: selecionado,
      selectedColor: cor,
      labelStyle: TextStyle(
        color: selecionado ? Colors.white : Colors.black87,
        fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => onTap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatadorData = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contatos Recebidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de Destaque: Contatos Sem Retorno Anotado (Critério 6)
          if (!_carregando && _erro == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: _quantidadeSemRetorno > 0
                  ? Colors.amber.shade100
                  : Colors.green.shade100,
              child: Row(
                children: [
                  Icon(
                    _quantidadeSemRetorno > 0
                        ? Icons.pending_actions
                        : Icons.check_circle_outline,
                    color: _quantidadeSemRetorno > 0
                        ? Colors.amber.shade900
                        : Colors.green.shade900,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _quantidadeSemRetorno > 0
                          ? '$_quantidadeSemRetorno contatos sem retorno anotado'
                          : 'Todos os contatos possuem retorno anotado!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _quantidadeSemRetorno > 0
                            ? Colors.amber.shade900
                            : Colors.green.shade900,
                      ),
                    ),
                  ),
                  if (_quantidadeSemRetorno > 0)
                    FilterChip(
                      label: const Text('Ver pendentes', style: TextStyle(fontSize: 12)),
                      selected: _apenasSemRetorno,
                      onSelected: (val) {
                        setState(() => _apenasSemRetorno = val);
                        _carregarDados();
                      },
                    ),
                ],
              ),
            ),

          // Filtros por Imóvel e por Período (Critério 3)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: _imovelIdSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por Imóvel',
                    isDense: true,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos os imóveis'),
                    ),
                    ..._imoveisCorretor.map(
                      (imovel) => DropdownMenuItem<String?>(
                        value: imovel.id,
                        child: Text(
                          '${imovel.codigo} - ${imovel.titulo}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _imovelIdSelecionado = val);
                    _carregarDados();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: FiltroPeriodo.values.map((periodo) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(periodo.rotulo, style: const TextStyle(fontSize: 12)),
                                selected: _periodoSelecionado == periodo,
                                onSelected: (val) {
                                  if (val) {
                                    setState(() => _periodoSelecionado = periodo);
                                    _carregarDados();
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista dos Contatos (Critério 1 e 2)
          Expanded(
            child: _carregando
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
                    : _contatos.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum contato encontrado para os filtros selecionados.',
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _carregarDados,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _contatos.length,
                              itemBuilder: (context, index) {
                                final contato = _contatos[index];
                                return _cardContato(contato, formatadorData);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _cardContato(ContatoRecebido contato, DateFormat formatador) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Miniatura do imóvel
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey.shade200,
                    child: contato.imovelImagemUrl.isNotEmpty
                        ? Image.network(
                            contato.imovelImagemUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.home, size: 30),
                          )
                        : const Icon(Icons.home, size: 30),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contato.imovelTitulo,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Código: ${contato.imovelCodigo}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _badgeCanal(contato.canal),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      formatador.format(contato.dataContato),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                if (contato.nomeCliente != null)
                  Text(
                    contato.nomeCliente!,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _badgeStatusRetorno(contato.retorno),
                OutlinedButton.icon(
                  onPressed: () => _abrirModalAnotarRetorno(contato),
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: Text(
                    contato.temRetornoAnotado ? 'Editar Retorno' : 'Anotar Retorno',
                  ),
                ),
              ],
            ),
            if (contato.observacaoRetorno != null &&
                contato.observacaoRetorno!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Obs: ${contato.observacaoRetorno}',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badgeCanal(CanalContato canal) {
    IconData icone = Icons.chat;
    Color cor = Colors.green;
    String texto = 'WhatsApp';

    switch (canal) {
      case CanalContato.whatsapp:
        icone = Icons.chat;
        cor = Colors.green;
        texto = 'WhatsApp';
        break;
      case CanalContato.telefone:
        icone = Icons.phone;
        cor = Colors.blue;
        texto = 'Telefone';
        break;
      case CanalContato.email:
        icone = Icons.email;
        cor = Colors.orange;
        texto = 'E-mail';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: cor),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _badgeStatusRetorno(RetornoContato? retorno) {
    if (retorno == null || retorno == RetornoContato.pendente) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Sem retorno anotado',
          style: TextStyle(
            color: Colors.amber.shade900,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    Color cor = Colors.amber;
    switch (retorno) {
      case RetornoContato.falei:
        cor = Colors.green;
        break;
      case RetornoContato.visitaAgendada:
        cor = Colors.blue;
        break;
      case RetornoContato.semResposta:
        cor = Colors.orange;
        break;
      case RetornoContato.descartado:
        cor = Colors.grey;
        break;
      case RetornoContato.pendente:
        cor = Colors.amber;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        retorno.rotulo,
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

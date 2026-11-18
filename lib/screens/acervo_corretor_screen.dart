import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/imovel.dart';
import '../models/imovel_enums.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AcervoCorretorScreen extends StatefulWidget {
  const AcervoCorretorScreen({super.key});

  @override
  State<AcervoCorretorScreen> createState() => _AcervoCorretorScreenState();
}

class _AcervoCorretorScreenState extends State<AcervoCorretorScreen> {
  final _api = ApiClient();
  final _auth = AuthService();
  final _buscaController = TextEditingController();

  List<Imovel> _imoveis = const [];
  bool _carregando = true;
  String? _erro;
  String _busca = '';
  String _filtroSituacao = 'TODOS';

  @override
  void initState() {
    super.initState();
    _carregarAcervo();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarAcervo() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resposta = await _api.get('/imovel');
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is! List) {
        throw const FormatException(
          'A API retornou uma lista de imóveis inválida.',
        );
      }
      final imoveis = corpo
          .map((item) => Imovel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _imoveis = imoveis;
        _carregando = false;
      });
    } on ApiAuthenticationException catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro.mensagem;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar o acervo. Tente novamente.';
        _carregando = false;
      });
    }
  }

  List<Imovel> get _imoveisFiltrados {
    final termo = _busca.trim().toLowerCase();
    return _imoveis.where((imovel) {
      final correspondeBusca = termo.isEmpty ||
          imovel.titulo.toLowerCase().contains(termo) ||
          imovel.codigo.toLowerCase().contains(termo) ||
          imovel.bairro.toLowerCase().contains(termo) ||
          imovel.cidade.toLowerCase().contains(termo);
      final situacao =
          imovel.situacao?.name.toUpperCase() ?? 'SEM_INFORMACAO';
      final correspondeSituacao = _filtroSituacao == 'TODOS' ||
          situacao == _filtroSituacao;
      return correspondeBusca && correspondeSituacao;
    }).toList(growable: false);
  }

  String _rotuloSituacao(SituacaoImovel? situacao) {
    switch (situacao) {
      case SituacaoImovel.disponivel:
        return 'Disponível';
      case SituacaoImovel.vendido:
        return 'Vendido';
      case SituacaoImovel.alugado:
        return 'Alugado';
      case SituacaoImovel.despublicado:
        return 'Despublicado';
      case null:
        return 'Situação não informada';
    }
  }

  String _rotuloFiltro(String valor) {
    switch (valor) {
      case 'DISPONIVEL':
        return 'Disponíveis';
      case 'VENDIDO':
        return 'Vendidos';
      case 'ALUGADO':
        return 'Alugados';
      case 'DESPUBLICADO':
        return 'Despublicados';
      case 'SEM_INFORMACAO':
        return 'Sem situação';
      default:
        return 'Todas as situações';
    }
  }

  Future<void> _sair() async {
    await _auth.sair();
    if (mounted) Navigator.of(context).popUntil((rota) => rota.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final resultados = _imoveisFiltrados;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acervo da imobiliária'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/contatos-recebidos'),
            icon: const Icon(Icons.inbox),
            tooltip: 'Contatos recebidos',
          ),
          TextButton.icon(
            onPressed: _sair,
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _buscaController,
              onChanged: (valor) => setState(() => _busca = valor),
              decoration: const InputDecoration(
                labelText: 'Buscar no acervo',
                hintText: 'Título, código, bairro ou cidade',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<String>(
              initialValue: _filtroSituacao,
              decoration: const InputDecoration(
                labelText: 'Filtrar por situação',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.filter_list),
              ),
              items: const [
                'TODOS',
                'DISPONIVEL',
                'VENDIDO',
                'ALUGADO',
                'DESPUBLICADO',
                'SEM_INFORMACAO',
              ].map(
                (valor) => DropdownMenuItem(
                  value: valor,
                  child: Text(_rotuloFiltro(valor)),
                ),
              ).toList(),
              onChanged: (valor) {
                if (valor != null) setState(() => _filtroSituacao = valor);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${resultados.length} imóveis no acervo'),
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _erro != null
                    ? _EstadoAcervo(
                        mensagem: _erro!,
                        acao: FilledButton.icon(
                          onPressed: _carregarAcervo,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      )
                    : resultados.isEmpty
                        ? const _EstadoAcervo(
                            mensagem:
                                'Nenhum imóvel encontrado com esses filtros.',
                          )
                        : RefreshIndicator(
                            onRefresh: _carregarAcervo,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: resultados.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final imovel = resultados[index];
                                return Card(
                                  clipBehavior: Clip.antiAlias,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: imovel.imagemUrl.isEmpty
                                          ? const Icon(Icons.home_work_outlined, size: 36)
                                          : ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                imovel.imagemUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    const Icon(Icons.home_work_outlined),
                                              ),
                                            ),
                                    ),
                                    title: Text(
                                      imovel.titulo,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${imovel.codigo.isEmpty ? 'Sem código' : imovel.codigo} · ${imovel.bairro}, ${imovel.cidade}',
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Corretor: ${imovel.corretorNome.isEmpty ? 'não informado' : imovel.corretorNome}',
                                          ),
                                          Text(_rotuloSituacao(imovel.situacao)),
                                        ],
                                      ),
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/detalhes-imovel',
                                      arguments: imovel,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _EstadoAcervo extends StatelessWidget {
  final String mensagem;
  final Widget? acao;

  const _EstadoAcervo({required this.mensagem, this.acao});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mensagem, textAlign: TextAlign.center),
              if (acao != null) ...[const SizedBox(height: 12), acao!],
            ],
          ),
        ),
      );
}

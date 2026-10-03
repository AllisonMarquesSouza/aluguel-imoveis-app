import 'package:flutter/material.dart';
import '../models/filtros_vitrine.dart';
import '../models/imovel.dart';
import '../services/imovel_service.dart';
import '../widgets/imovel_card.dart';
import 'filtros_vitrine_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImovelService _service = ImovelServiceApi();
  final ScrollController _scrollController = ScrollController();

  String cidadeAtual = 'Serra Talhada';
  String termoBusca = '';
  TipoOrdenacao ordenacaoSelecionada = TipoOrdenacao.maisRecentes;
  FiltrosVitrine filtrosVitrine = const FiltrosVitrine();

  List<Imovel> listaImoveis = [];
  bool carregando = false;
  int paginaAtual = 1;
  int totalResultados = 0;
  String? erroCarregamento;

  @override
  void initState() {
    super.initState();
    _carregarImoveis();
    _scrollController.addListener(_aoRolarATela);
  }

  void _aoRolarATela() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Gatilho para carregar próximas páginas ao rolar
      _carregarMaisImoveis();
    }
  }

  Future<void> _carregarImoveis() async {
    setState(() {
      carregando = true;
      paginaAtual = 1;
      erroCarregamento = null;
    });

    try {
      final resultados = await _service.getImoveis(
        cidade: cidadeAtual,
        busca: termoBusca,
        ordenacao: ordenacaoSelecionada,
        filtros: filtrosVitrine,
        pagina: paginaAtual,
      );

      if (!mounted) return;

      setState(() {
        listaImoveis = resultados.imoveis;
        totalResultados = resultados.total;
        carregando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        listaImoveis = [];
        totalResultados = 0;
        erroCarregamento = 'Não foi possível carregar os imóveis.';
        carregando = false;
      });
    }
  }
  

  Future<void> _abrirFiltros() async {
    final filtrosSelecionados = await showModalBottomSheet<FiltrosVitrine>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FiltrosVitrineSheet(
        filtrosIniciais: filtrosVitrine,
      ),
    );

    if (filtrosSelecionados == null || !mounted) return;

    setState(() {
      filtrosVitrine = filtrosSelecionados;
    });

    _carregarImoveis();
  }

  Future<void> _carregarMaisImoveis() async {
    if (carregando) return;
    // Lógica para incremental paging
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: GestureDetector(
          onTap: () async {
              final novaCidade = await Navigator.pushNamed(
                context,
                '/selecionar-cidade',
              );

              if (novaCidade != null && novaCidade is String) {
                setState(() {
                  cidadeAtual = novaCidade;
                });
                _carregarImoveis();
              }
            },
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent, size: 22),
              const SizedBox(width: 6),
              Text(
                cidadeAtual,
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Barra de Pesquisa e Ordenação
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (valor) {
                    termoBusca = valor;
                    _carregarImoveis();
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por título ou bairro...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _abrirFiltros,
                    icon: const Icon(Icons.tune),
                    label: Text(
                      filtrosVitrine.estaVazio
                          ? 'Filtros'
                          : 'Filtros aplicados',
                    ),
                  ),
                ),
                // Chips de Ordenação
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _criarChipOrdenacao('Mais Recentes', TipoOrdenacao.maisRecentes),
                      _criarChipOrdenacao('Menor Preço', TipoOrdenacao.menorPreco),
                      _criarChipOrdenacao('Maior Preço', TipoOrdenacao.maiorPreco),
                      _criarChipOrdenacao('Maior Área', TipoOrdenacao.maiorArea),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$totalResultados '
                '${totalResultados == 1 ? 'imóvel encontrado' : 'imóveis encontrados'}',
              ),
            ),
          ),

          // Lista da Vitrine
          Expanded(
            child: carregando
                ? const Center(child: CircularProgressIndicator())
                : erroCarregamento != null
    ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(erroCarregamento!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _carregarImoveis,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      )
      : listaImoveis.isEmpty
        ? const Center(
            child: Text('Nada encontrado. Tente alterar ou limpar os filtros.'),
          )
        : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: listaImoveis.length,
              itemBuilder: (context, index) {
                final imovel = listaImoveis[index];
                return ImovelCard(
                  imovel: imovel,
                  onTap: () {
                    Navigator.pushNamed(context, '/detalhes-imovel', arguments: imovel.id,);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _criarChipOrdenacao(String rotulo, TipoOrdenacao tipo) {
    final selecionado = ordenacaoSelecionada == tipo;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(rotulo),
        selected: selecionado,
        onSelected: (val) {
          if (val) {
            setState(() {
              ordenacaoSelecionada = tipo;
            });
            _carregarImoveis();
          }
        },
        selectedColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: selecionado ? Colors.white : Colors.black87,
          fontSize: 12,
        ),
      ),
    );
  }
}
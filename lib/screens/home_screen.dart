import 'package:flutter/material.dart';
import '../models/imovel.dart';
import '../services/favoritos_service.dart';
import '../services/imovel_service.dart';
import '../widgets/imovel_card.dart';

class HomeScreen extends StatefulWidget {
  final bool? temaEscuro;
  final ValueChanged<bool>? onTemaAlterado;
  final FavoritosService? favoritosService;

  const HomeScreen({
    super.key,
    this.temaEscuro,
    this.onTemaAlterado,
    this.favoritosService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImovelService _service = ImovelServiceApi();
  final ScrollController _scrollController = ScrollController();

  String cidadeAtual = 'São Paulo';
  String termoBusca = '';
  TipoOrdenacao ordenacaoSelecionada = TipoOrdenacao.maisRecentes;

  List<Imovel> listaImoveis = [];
  bool carregando = false;
  int paginaAtual = 1;

  @override
  void initState() {
    super.initState();
    _carregarImoveis();
    _scrollController.addListener(_aoRolarATela);
  }

  void _aoRolarATela() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _carregarMaisImoveis();
    }
  }

  Future<void> _carregarImoveis() async {
    setState(() {
      carregando = true;
      paginaAtual = 1;
    });

    final resultados = await _service.getImoveis(
      cidade: cidadeAtual,
      busca: termoBusca,
      ordenacao: ordenacaoSelecionada,
      pagina: paginaAtual,
    );

    setState(() {
      listaImoveis = resultados;
      carregando = false;
    });
  }

  Future<void> _carregarMaisImoveis() async {
    if (carregando) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        title: GestureDetector(
          onTap: () async {
            final novaCidade = await Navigator.pushNamed(context, '/selecionar-cidade');
            if (novaCidade != null && novaCidade is String) {
              if (!mounted) return;
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
              Flexible(
                child: Text(
                  cidadeAtual,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_ind_outlined),
            tooltip: 'Portal do Cliente',
            onPressed: () {
              Navigator.pushNamed(context, '/area-cliente');
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Área do Gestor',
            onPressed: () {
              Navigator.pushNamed(context, '/area-gestor');
            },
          ),
          IconButton(
            icon: const Icon(Icons.inbox),
            tooltip: 'Contatos recebidos',
            onPressed: () {
              Navigator.pushNamed(context, '/contatos-recebidos');
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.pushNamed(context, '/favoritos');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de Pesquisa e Ordenação
          Container(
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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

          // Lista da Vitrine
          Expanded(
            child: carregando
                ? const Center(child: CircularProgressIndicator())
                : listaImoveis.isEmpty
                    ? const Center(child: Text('Nenhum imóvel encontrado.'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: listaImoveis.length,
                        itemBuilder: (context, index) {
                          final imovel = listaImoveis[index];
                          final isFav = widget.favoritosService?.favoritos.value
                                  .any((item) => item.id == imovel.id) ??
                              false;
                          return ImovelCard(
                            imovel: imovel,
                            isFavorito: isFav,
                            onAlternarFavorito: () {
                              widget.favoritosService?.alternar(imovel);
                              setState(() {});
                            },
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/detalhes-imovel',
                                arguments: imovel,
                              );
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
          color: selecionado ? Colors.white : Theme.of(context).colorScheme.onSurface,
          fontSize: 12,
        ),
      ),
    );
  }
}

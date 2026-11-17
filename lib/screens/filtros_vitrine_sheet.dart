import 'package:flutter/material.dart';
import '../models/filtros_vitrine.dart';

class FiltrosVitrineSheet extends StatefulWidget {
  final FiltrosVitrine filtrosIniciais;

  const FiltrosVitrineSheet({
    super.key,
    required this.filtrosIniciais,
  });

  @override
  State<FiltrosVitrineSheet> createState() => _FiltrosVitrineSheetState();
}

class _FiltrosVitrineSheetState extends State<FiltrosVitrineSheet> {
  static const _opcoesCaracteristicas = [
    'Piscina',
    'Varanda',
    'Churrasqueira',
    'Elevador',
    'Academia',
    'Portaria 24h',
    'Mobiliado',
    'Aceita pets',
  ];

  late String? _finalidade = widget.filtrosIniciais.finalidade;
  late String? _natureza = widget.filtrosIniciais.natureza;

  late final _precoMinimo = _criarController(widget.filtrosIniciais.precoMinimo);
  late final _precoMaximo = _criarController(widget.filtrosIniciais.precoMaximo);
  late final _quartos = _criarController(widget.filtrosIniciais.quartosMinimos);
  late final _suites = _criarController(widget.filtrosIniciais.suitesMinimas);
  late final _vagas = _criarController(widget.filtrosIniciais.vagasMinimas);
  late final _bairro = TextEditingController(
    text: widget.filtrosIniciais.bairro ?? '',
  );
  late final _areaMinima = _criarController(widget.filtrosIniciais.areaMinimaM2);
  late final _areaMaxima = _criarController(widget.filtrosIniciais.areaMaximaM2);

  late final Set<String> _caracteristicasSelecionadas =
      widget.filtrosIniciais.caracteristicas.toSet();

  TextEditingController _criarController(num? valor) =>
      TextEditingController(text: valor?.toString() ?? '');

  double? _decimal(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  int? _inteiro(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  Widget _campo(
    String rotulo,
    TextEditingController controller, {
    String? prefixo,
    TextInputType teclado = const TextInputType.numberWithOptions(decimal: true),
  }) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      decoration: InputDecoration(
        labelText: rotulo,
        prefixText: prefixo,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _opcoes(
    String titulo,
    String? selecionada,
    List<String> opcoes,
    ValueChanged<String?> aoSelecionar,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Todas'),
              selected: selecionada == null,
              onSelected: (_) => aoSelecionar(null),
            ),
            ...opcoes.map(
              (opcao) => ChoiceChip(
                label: Text(opcao),
                selected: selecionada == opcao.toLowerCase(),
                onSelected: (_) => aoSelecionar(opcao.toLowerCase()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _aplicar() {
    final precoMinimo = _decimal(_precoMinimo);
    final precoMaximo = _decimal(_precoMaximo);
    final areaMinima = _decimal(_areaMinima);
    final areaMaxima = _decimal(_areaMaxima);

    if (precoMinimo != null &&
        precoMaximo != null &&
        precoMinimo > precoMaximo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O preço mínimo supera o máximo.')),
      );
      return;
    }

    if (areaMinima != null && areaMaxima != null && areaMinima > areaMaxima) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A área mínima supera a máxima.')),
      );
      return;
    }

    Navigator.pop(
      context,
      FiltrosVitrine(
        finalidade: _finalidade,
        natureza: _natureza,
        precoMinimo: precoMinimo,
        precoMaximo: precoMaximo,
        quartosMinimos: _inteiro(_quartos),
        suitesMinimas: _inteiro(_suites),
        vagasMinimas: _inteiro(_vagas),
        bairro: _bairro.text.trim().isEmpty ? null : _bairro.text.trim(),
        areaMinimaM2: areaMinima,
        areaMaximaM2: areaMaxima,
        caracteristicas: _caracteristicasSelecionadas.toList(),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _precoMinimo,
      _precoMaximo,
      _quartos,
      _suites,
      _vagas,
      _bairro,
      _areaMinima,
      _areaMaxima,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.85,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtrar imóveis',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  children: [
                    _opcoes('Finalidade', _finalidade, ['Venda', 'Aluguel'],
                        (valor) => setState(() => _finalidade = valor)),
                    const SizedBox(height: 16),
                    _opcoes(
                      'Natureza',
                      _natureza,
                      ['Casa', 'Apartamento', 'Terreno', 'Lote'],
                      (valor) => setState(() => _natureza = valor),
                    ),
                    const SizedBox(height: 16),
                    const Text('Faixa de preço'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _campo('Mínimo', _precoMinimo, prefixo: 'R\$ '),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _campo('Máximo', _precoMaximo, prefixo: 'R\$ '),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Quantidades mínimas'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _campo(
                            'Quartos',
                            _quartos,
                            teclado: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _campo(
                            'Suítes',
                            _suites,
                            teclado: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _campo(
                            'Vagas',
                            _vagas,
                            teclado: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _campo(
                      'Bairro',
                      _bairro,
                      teclado: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    const Text('Faixa de área (m²)'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _campo('Mínima', _areaMinima)),
                        const SizedBox(width: 12),
                        Expanded(child: _campo('Máxima', _areaMaxima)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Características',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Wrap(
                      spacing: 8,
                      children: _opcoesCaracteristicas.map((opcao) {
                        final selecionada =
                            _caracteristicasSelecionadas.contains(opcao);
                        return FilterChip(
                          label: Text(opcao),
                          selected: selecionada,
                          onSelected: (valor) {
                            setState(() {
                              if (valor) {
                                _caracteristicasSelecionadas.add(opcao);
                              } else {
                                _caracteristicasSelecionadas.remove(opcao);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, const FiltrosVitrine()),
                    child: const Text('Limpar filtros'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _aplicar,
                      child: const Text('Aplicar filtros'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
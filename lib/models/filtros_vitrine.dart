class FiltrosVitrine {
  final String? finalidade; // venda ou aluguel
  final String? natureza; // casa, apartamento, terreno ou lote
  final double? precoMinimo;
  final double? precoMaximo;
  final int? quartosMinimos;
  final int? suitesMinimas;
  final int? vagasMinimas;
  final String? bairro;
  final double? areaMinimaM2;
  final double? areaMaximaM2;
  final List<String> caracteristicas;

  const FiltrosVitrine({
    this.finalidade,
    this.natureza,
    this.precoMinimo,
    this.precoMaximo,
    this.quartosMinimos,
    this.suitesMinimas,
    this.vagasMinimas,
    this.bairro,
    this.areaMinimaM2,
    this.areaMaximaM2,
    this.caracteristicas = const [],
  });

  bool get estaVazio =>
      finalidade == null &&
      natureza == null &&
      precoMinimo == null &&
      precoMaximo == null &&
      quartosMinimos == null &&
      suitesMinimas == null &&
      vagasMinimas == null &&
      (bairro == null || bairro!.trim().isEmpty) &&
      areaMinimaM2 == null &&
      areaMaximaM2 == null &&
      caracteristicas.isEmpty;

}

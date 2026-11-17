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

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (finalidade != null) params['finalidade'] = finalidade!;
    if (natureza != null) params['natureza'] = natureza!;
    if (precoMinimo != null) params['precoMinimo'] = precoMinimo!.toString();
    if (precoMaximo != null) params['precoMaximo'] = precoMaximo!.toString();
    if (quartosMinimos != null) params['quartosMinimos'] = quartosMinimos!.toString();
    if (suitesMinimas != null) params['suitesMinimas'] = suitesMinimas!.toString();
    if (vagasMinimas != null) params['vagasMinimas'] = vagasMinimas!.toString();
    if (bairro != null && bairro!.trim().isNotEmpty) params['bairro'] = bairro!.trim();
    if (areaMinimaM2 != null) params['areaMinimaM2'] = areaMinimaM2!.toString();
    if (areaMaximaM2 != null) params['areaMaximaM2'] = areaMaximaM2!.toString();
    if (caracteristicas.isNotEmpty) params['caracteristicas'] = caracteristicas.join(',');
    return params;
  }
}

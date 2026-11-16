import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/imovel.dart';
import '../models/imovel_enums.dart';

class FavoritosService {
  static const String _chave = 'imoveis_favoritos_v1';

  final SharedPreferencesAsync _preferencias;
  final ValueNotifier<List<Imovel>> favoritos =
      ValueNotifier<List<Imovel>>([]);

  FavoritosService(this._preferencias);

  Future<void> carregar() async {
    final salvo = await _preferencias.getString(_chave);
    if (salvo == null || salvo.isEmpty) return;

    try {
      final dados = jsonDecode(salvo);

      if (dados is! List) {
        throw const FormatException('Lista de favoritos inválida.');
      }

      favoritos.value = dados
          .map(
            (item) => Imovel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      favoritos.value = [];

      try {
        await _preferencias.remove(_chave);
      } catch (_) {
        // O app continua mesmo se não conseguir limpar os dados inválidos.
      }
    }
  }

  Future<void> alternar(Imovel imovel) async {
    final atuais = List<Imovel>.from(favoritos.value);
    final indice = atuais.indexWhere((item) => item.id == imovel.id);

    if (indice >= 0) {
      atuais.removeAt(indice);
    } else {
      atuais.insert(0, imovel);
    }

    favoritos.value = List.unmodifiable(atuais);

    await _preferencias.setString(
      _chave,
      jsonEncode(atuais.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> atualizarSituacao(String id, SituacaoImovel situacao) async {
    final atuais = List<Imovel>.from(favoritos.value);
    final indice = atuais.indexWhere((imovel) => imovel.id == id);

    if (indice < 0) return;

    atuais[indice] = atuais[indice].copyWith(situacao: situacao);
    favoritos.value = List.unmodifiable(atuais);

    await _preferencias.setString(
      _chave,
      jsonEncode(atuais.map((imovel) => imovel.toJson()).toList()),
    );
  }
}

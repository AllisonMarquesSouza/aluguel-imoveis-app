import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/perfil_usuario.dart';

class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  static const String _chaveToken = 'sessao_token_v1';
  static const String _chaveEmail = 'sessao_email_v1';
  static const String _chavePerfil = 'sessao_perfil_v1';

  String? _token;
  String? _email;
  PerfilUsuario? _perfil;

  String? get token => _token;
  String? get email => _email;
  PerfilUsuario get perfil => _perfil ?? PerfilUsuario.deString(null, _email);
  bool get autenticado => _token != null;
  bool get eGestorOuAdmin => perfil.eGestorOuAdmin;

  Future<void> restaurar(SharedPreferencesAsync preferencias) async {
    _token = await preferencias.getString(_chaveToken);
    _email = await preferencias.getString(_chaveEmail);
    final perfilStr = await preferencias.getString(_chavePerfil);
    _perfil = PerfilUsuario.deString(perfilStr, _email);
  }

  Future<void> iniciar(String token, {String? email, String? perfilStr}) async {
    _token = token;
    _email = email ?? _extrairEmailDoJwt(token);
    final pStr = perfilStr ?? _extrairPerfilDoJwt(token);
    _perfil = PerfilUsuario.deString(pStr, _email);

    final prefs = SharedPreferencesAsync();
    await prefs.setString(_chaveToken, token);
    if (_email != null) await prefs.setString(_chaveEmail, _email!);
    if (pStr != null) await prefs.setString(_chavePerfil, pStr);
  }

  Future<void> encerrar() async {
    _token = null;
    _email = null;
    _perfil = null;
    final prefs = SharedPreferencesAsync();
    await prefs.remove(_chaveToken);
    await prefs.remove(_chaveEmail);
    await prefs.remove(_chavePerfil);
  }

  String? _extrairEmailDoJwt(String token) {
    final payload = _decodificarPayloadJwt(token);
    return payload?['sub']?.toString() ?? payload?['email']?.toString();
  }

  String? _extrairPerfilDoJwt(String token) {
    final payload = _decodificarPayloadJwt(token);
    return payload?['perfil']?.toString() ?? payload?['role']?.toString();
  }

  Map<String, dynamic>? _decodificarPayloadJwt(String token) {
    try {
      final partes = token.split('.');
      if (partes.length < 2) return null;
      final normalizada = base64Url.normalize(partes[1]);
      final payloadString = utf8.decode(base64Url.decode(normalizada));
      return jsonDecode(payloadString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

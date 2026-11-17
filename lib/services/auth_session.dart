import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  static const String _chaveToken = 'sessao_token_v1';

  String? _token;

  String? get token => _token;
  bool get autenticado => _token != null;

  Future<void> restaurar(SharedPreferencesAsync preferencias) async {
    _token = await preferencias.getString(_chaveToken);
  }

  Future<void> iniciar(String token) async {
    _token = token;
    await SharedPreferencesAsync().setString(_chaveToken, token);
  }

  Future<void> encerrar() async {
    _token = null;
    await SharedPreferencesAsync().remove(_chaveToken);
  }
}

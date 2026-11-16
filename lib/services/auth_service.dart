import 'api_client.dart';
import 'auth_session.dart';

class AuthService {
  final ApiClient _api;
  final AuthSession _sessao;

  AuthService({ApiClient? apiClient, AuthSession? sessao})
      : _api = apiClient ?? ApiClient(),
        _sessao = sessao ?? AuthSession.instance;

  Future<void> entrar({required String email, required String senha}) async {
    final token = await _api.autenticar(email: email, senha: senha);
    await _sessao.iniciar(token);
  }

  Future<void> sair() => _sessao.encerrar();
}

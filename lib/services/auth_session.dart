class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  String? _token;

  String? get token => _token;
  bool get autenticado => _token != null;

  void iniciar(String token) {
    _token = token;
  }

  void encerrar() {
    _token = null;
  }
}

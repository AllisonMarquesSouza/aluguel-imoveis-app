import 'package:shared_preferences/shared_preferences.dart';

class SessaoCliente {
  final String cpf;
  final String nome;
  final String email;
  final bool primeiroAcesso;
  final String token;

  const SessaoCliente({
    required this.cpf,
    required this.nome,
    required this.email,
    required this.primeiroAcesso,
    required this.token,
  });

  SessaoCliente copyWith({
    String? cpf,
    String? nome,
    String? email,
    bool? primeiroAcesso,
    String? token,
  }) {
    return SessaoCliente(
      cpf: cpf ?? this.cpf,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      primeiroAcesso: primeiroAcesso ?? this.primeiroAcesso,
      token: token ?? this.token,
    );
  }
}

class ClienteAuthSession {
  ClienteAuthSession._();
  static final ClienteAuthSession instance = ClienteAuthSession._();

  static const String _chaveToken = 'cliente_sessao_token_v1';
  static const String _chaveCpf = 'cliente_sessao_cpf_v1';
  static const String _chaveNome = 'cliente_sessao_nome_v1';
  static const String _chavePrimeiroAcesso = 'cliente_sessao_primeiro_acesso_v1';

  SessaoCliente? _sessao;

  SessaoCliente? get sessao => _sessao;
  bool get autenticado => _sessao != null;
  bool get exigeTrocaSenha => _sessao != null && _sessao!.primeiroAcesso;

  Future<void> restaurar(SharedPreferencesAsync preferencias) async {
    final token = await preferencias.getString(_chaveToken);
    final cpf = await preferencias.getString(_chaveCpf);
    final nome = await preferencias.getString(_chaveNome);
    final primeiroAcesso = await preferencias.getBool(_chavePrimeiroAcesso) ?? false;

    if (token != null && cpf != null) {
      _sessao = SessaoCliente(
        cpf: cpf,
        nome: nome ?? 'Cliente',
        email: '',
        primeiroAcesso: primeiroAcesso,
        token: token,
      );
    }
  }

  Future<void> iniciar(SessaoCliente sessao) async {
    _sessao = sessao;
    final prefs = SharedPreferencesAsync();
    await prefs.setString(_chaveToken, sessao.token);
    await prefs.setString(_chaveCpf, sessao.cpf);
    await prefs.setString(_chaveNome, sessao.nome);
    await prefs.setBool(_chavePrimeiroAcesso, sessao.primeiroAcesso);
  }

  Future<void> concluirTrocaSenha() async {
    if (_sessao != null) {
      _sessao = _sessao!.copyWith(primeiroAcesso: false);
      final prefs = SharedPreferencesAsync();
      await prefs.setBool(_chavePrimeiroAcesso, false);
    }
  }

  Future<void> encerrar() async {
    _sessao = null;
    final prefs = SharedPreferencesAsync();
    await prefs.remove(_chaveToken);
    await prefs.remove(_chaveCpf);
    await prefs.remove(_chaveNome);
    await prefs.remove(_chavePrimeiroAcesso);
  }
}

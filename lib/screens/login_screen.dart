import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/auth_session.dart';

const String _emailAdminDemo = 'admin@demo.meu-imovel.test';
const String _senhaAdminDemo = 'AdminDemo123!';
const String _emailCorretorDemo = 'corretor@demo.meu-imovel.test';
const String _senhaCorretorDemo = 'CorretorDemo123!';
const bool _mostrarContasTeste =
    kDebugMode || bool.fromEnvironment('APP_TEST_MODE');

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _authService = AuthService();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await _authService.entrar(
        email: _emailController.text.trim(),
        senha: _senhaController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (erro) {
      if (mounted) setState(() => _erro = erro.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível entrar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _preencherCredenciais(String email, String senha) {
    _emailController.text = email;
    _senhaController.text = senha;
    setState(() => _erro = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acesso do corretor'),
        actions: [
          if (AuthSession.instance.autenticado)
            TextButton(
              onPressed: () {
                _authService.sair();
                Navigator.pop(context, true);
              },
              child: const Text('Sair'),
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Entre com uma conta de corretor ativa para consultar as cidades e os imóveis vinculados à sua empresa.',
                  textAlign: TextAlign.center,
                ),
                if (_mostrarContasTeste) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: ExpansionTile(
                      leading: const Icon(Icons.science_outlined),
                      title: const Text('Contas locais de demonstração'),
                      subtitle: const Text(
                        'Disponíveis somente durante o desenvolvimento',
                      ),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: const Text('Corretor de demonstração'),
                          subtitle: const Text(_emailCorretorDemo),
                          onTap: () => _preencherCredenciais(
                            _emailCorretorDemo,
                            _senhaCorretorDemo,
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.admin_panel_settings_outlined),
                          title: const Text('Administrador de demonstração'),
                          subtitle: const Text(
                            'Para testar o login; não acessa a lista de imóveis.',
                          ),
                          onTap: () => _preencherCredenciais(
                            _emailAdminDemo,
                            _senhaAdminDemo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username, AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Informe seu e-mail.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _senhaController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Informe sua senha.'
                      : null,
                  onFieldSubmitted: (_) {
                    if (!_carregando) _entrar();
                  },
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _erro!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _carregando ? null : _entrar,
                  child: _carregando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

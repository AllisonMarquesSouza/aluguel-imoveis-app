import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/cliente_contrato_service.dart';

class LoginClienteScreen extends StatefulWidget {
  const LoginClienteScreen({super.key});

  @override
  State<LoginClienteScreen> createState() => _LoginClienteScreenState();
}

class _LoginClienteScreenState extends State<LoginClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();
  final _clienteService = ClienteContratoService();

  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _cpfController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final nav = Navigator.of(context);

    try {
      final sessao = await _clienteService.loginCliente(
        cpf: _cpfController.text.trim(),
        senha: _senhaController.text,
      );

      if (!mounted) return;

      // Critério 1: Troca obrigatória de senha no primeiro acesso
      if (sessao.primeiroAcesso) {
        await _exibirModalTrocaSenhaObrigatoria();
      }

      nav.pushReplacementNamed('/area-cliente');
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível fazer login. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _exibirModalTrocaSenhaObrigatoria() async {
    final novaSenhaController = TextEditingController();
    final confirmaSenhaController = TextEditingController();
    final formKeyModal = GlobalKey<FormState>();
    bool salvando = false;
    String? erroModal;

    await showDialog(
      context: context,
      barrierDismissible: false, // Troca é obrigatória, não pode fechar sem trocar
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setStateModal) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.lock_reset, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Primeiro Acesso'),
                ],
              ),
              content: Form(
                key: formKeyModal,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Por motivos de segurança, você precisa redefinir a sua senha no primeiro acesso.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: novaSenhaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nova Senha',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe a nova senha.';
                        if (v.length < 6) return 'Mínimo de 6 caracteres.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmaSenhaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar Nova Senha',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v != novaSenhaController.text) {
                          return 'As senhas não coincidem.';
                        }
                        return null;
                      },
                    ),
                    if (erroModal != null) ...[
                      const SizedBox(height: 8),
                      Text(erroModal!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: salvando
                      ? null
                      : () async {
                          if (!formKeyModal.currentState!.validate()) return;
                          setStateModal(() => salvando = true);
                          final messenger = ScaffoldMessenger.of(modalCtx);
                          final nav = Navigator.of(modalCtx);
                          try {
                            await _clienteService.trocarSenhaPrimeiroAcesso(
                              novaSenha: novaSenhaController.text,
                            );
                            nav.pop();
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Senha redefinida com sucesso!')),
                            );
                          } catch (e) {
                            setStateModal(() {
                              salvando = false;
                              erroModal = 'Erro ao alterar a senha. Tente novamente.';
                            });
                          }
                        },
                  child: salvando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar Nova Senha'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _preencherDemo() {
    _cpfController.text = '123.456.789-00';
    _senhaController.text = '123456';
    setState(() => _erro = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal do Cliente'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.assignment_ind_outlined, size: 70, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  'Acesse seus Contratos e Pagamentos',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Informe o CPF e a senha inicial fornecida no momento da assinatura do contrato.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _cpfController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CPF',
                    hintText: '000.000.000-00',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Informe o seu CPF.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Informe a sua senha.';
                    return null;
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
                ElevatedButton(
                  onPressed: _carregando ? null : _entrar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _carregando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Entrar no Portal', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _preencherDemo,
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Preencher dados de demonstração (CPF / 1º Acesso)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

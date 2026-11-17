import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/perfil_publico.dart';
import '../services/contato_service.dart';
import '../services/perfil_publico_service.dart';
import '../widgets/contato_corretor_actions.dart';

class PerfilCorretorScreen extends StatefulWidget {
  final int corretorId;

  const PerfilCorretorScreen({
    super.key,
    required this.corretorId,
  });

  @override
  State<PerfilCorretorScreen> createState() =>
      _PerfilCorretorScreenState();
}

class _PerfilCorretorScreenState extends State<PerfilCorretorScreen> {
  final PerfilPublicoService _service = PerfilPublicoService();
  late Future<CorretorPublico> _perfilFuture;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _perfilFuture = _service.buscarCorretor(widget.corretorId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do corretor')),
      body: FutureBuilder<CorretorPublico>(
        future: _perfilFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final indisponivel =
                snapshot.error is PerfilNaoDisponivelException;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      indisponivel
                          ? 'Este perfil não está disponível.'
                          : 'Não foi possível carregar este perfil.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => setState(_carregar),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final corretor = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 56,
                  backgroundImage: corretor.fotoUrl == null
                      ? null
                      : NetworkImage(
                          PerfilPublicoService
                              .resolverUrl(corretor.fotoUrl!)
                              .toString(),
                        ),
                  child: corretor.fotoUrl == null
                      ? const Icon(Icons.person, size: 56)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  corretor.nome,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Center(child: Text('CRECI: ${corretor.creci}')),
              if (corretor.apresentacao?.isNotEmpty == true) ...[
                const SizedBox(height: 20),
                Text(corretor.apresentacao!),
              ],
              const SizedBox(height: 12),
              ContatoCorretorActions(
                onRegistrarContato: (canal) =>
                    ContatoService().registrarNoPerfilDoCorretor(
                  corretorId: corretor.id.toString(),
                  canal: canal,
                ),
              ),
              if (corretor.empresa != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.business),
                    title: Text(corretor.empresa!.nome),
                    subtitle: const Text('Ver perfil da empresa'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PerfilEmpresaScreen(
                            empresa: corretor.empresa!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class PerfilEmpresaScreen extends StatelessWidget {
  final EmpresaPublica empresa;

  const PerfilEmpresaScreen({
    super.key,
    required this.empresa,
  });

  @override
  Widget build(BuildContext context) {
    final cidades = empresa.cidadesAtuacao
        .map((cidade) => '${cidade.nome} - ${cidade.uf}')
        .join(', ');

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil da empresa')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (empresa.logoMarcaUrl != null)
            Center(
              child: Image.network(
                PerfilPublicoService
                    .resolverUrl(empresa.logoMarcaUrl!)
                    .toString(),
                height: 120,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.business, size: 72),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            empresa.nome,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (empresa.creci?.isNotEmpty == true)
            Text('CRECI: ${empresa.creci}'),
          if (empresa.descricao?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Text(empresa.descricao!),
          ],
          if (cidades.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Cidades de atuação: $cidades'),
          ],
          if (empresa.logradouro?.isNotEmpty == true)
            Text(
              [
                empresa.logradouro,
                empresa.numero,
                empresa.bairro,
                empresa.cep,
              ].where((item) => item?.isNotEmpty == true).join(', '),
            ),
          if (empresa.telefone?.isNotEmpty == true)
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(empresa.telefone!),
              onTap: () => launchUrl(
                Uri(scheme: 'tel', path: empresa.telefone),
              ),
            ),
          if (empresa.whatsapp?.isNotEmpty == true)
            ListTile(
              leading: const Icon(Icons.chat),
              title: Text(empresa.whatsapp!),
              onTap: () {
                final numero =
                    empresa.whatsapp!.replaceAll(RegExp(r'[^0-9]'), '');
                launchUrl(Uri.https('wa.me', '/$numero'));
              },
            ),
          if (empresa.email?.isNotEmpty == true)
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(empresa.email!),
              onTap: () => launchUrl(
                Uri(scheme: 'mailto', path: empresa.email),
              ),
            ),
        ],
      ),
    );
  }
}

class PerfilEmpresaPorIdScreen extends StatefulWidget {
  final int empresaId;

  const PerfilEmpresaPorIdScreen({
    super.key,
    required this.empresaId,
  });

  @override
  State<PerfilEmpresaPorIdScreen> createState() =>
      _PerfilEmpresaPorIdScreenState();
}

class _PerfilEmpresaPorIdScreenState
    extends State<PerfilEmpresaPorIdScreen> {
  final PerfilPublicoService _service = PerfilPublicoService();
  late Future<EmpresaPublica> _empresaFuture;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _empresaFuture = _service.buscarEmpresa(widget.empresaId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EmpresaPublica>(
      future: _empresaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Perfil da empresa')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Perfil da empresa')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Não foi possível carregar o perfil desta empresa.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => setState(_carregar),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return PerfilEmpresaScreen(empresa: snapshot.data!);
      },
    );
  }
}

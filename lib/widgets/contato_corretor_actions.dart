import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/contato_service.dart';

class ContatoCorretorActions extends StatefulWidget {
  final Future<ContatoRegistrado> Function(CanalContato canal)
      onRegistrarContato;

  const ContatoCorretorActions({
    super.key,
    required this.onRegistrarContato,
  });

  @override
  State<ContatoCorretorActions> createState() =>
      _ContatoCorretorActionsState();
}

class _ContatoCorretorActionsState
    extends State<ContatoCorretorActions> {
  bool _enviando = false;

  Future<void> _contatar(CanalContato canal) async {
    if (_enviando) return;

    setState(() => _enviando = true);

    try {
      // Primeiro registra o evento na API.
      final contato = await widget.onRegistrarContato(canal);

      if (!mounted) return;

      final destino = contato.destinoPara(canal)?.trim();
      if (destino == null || destino.isEmpty) {
        _mostrarMensagem('Este canal de contato não está disponível.');
        return;
      }

      late final Uri uri;

            switch (canal) {
        case CanalContato.whatsapp:
          final numero = _normalizarNumeroWhatsapp(destino);
          final mensagem = contato.mensagem?.trim();

          if (numero == null || mensagem == null || mensagem.isEmpty) {
            _mostrarMensagem(
            'Confira o número de WhatsApp e a mensagem retornados pela API.',
            );
          return;
          }

          uri = Uri.https(
            'wa.me',
            '/$numero',
            {'text': mensagem},
          );
          break;

        case CanalContato.telefone:
          uri = Uri(scheme: 'tel', path: destino);
          break;

        case CanalContato.email:
          uri = Uri(scheme: 'mailto', path: destino);
          break;
      }

      final abriu = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!abriu && mounted) {
        _mostrarMensagem('Não foi possível abrir o aplicativo de contato.');
      }
    } catch (erro) {
      if (mounted) {
        _mostrarMensagem(erro.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

    String? _normalizarNumeroWhatsapp(String valor) {
    final numero = valor.replaceAll(RegExp(r'\D'), '');

    if (numero.length == 10 || numero.length == 11) {
      return '55$numero';
    }

    if ((numero.length == 12 || numero.length == 13) &&
        numero.startsWith('55')) {
      return numero;
    }

    return null;
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed:
              _enviando ? null : () => _contatar(CanalContato.whatsapp),
          icon: const Icon(Icons.chat),
          label: const Text('WhatsApp'),
        ),
        OutlinedButton.icon(
          onPressed:
              _enviando ? null : () => _contatar(CanalContato.telefone),
          icon: const Icon(Icons.phone),
          label: const Text('Ligar'),
        ),
        OutlinedButton.icon(
          onPressed:
              _enviando ? null : () => _contatar(CanalContato.email),
          icon: const Icon(Icons.email_outlined),
          label: const Text('E-mail'),
        ),
      ],
    );
  }
}

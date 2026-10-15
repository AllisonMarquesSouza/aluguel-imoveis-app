import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/imovel.dart';
import '../services/imovel_service.dart';

class DetalhesImovelScreen extends StatelessWidget {
  const DetalhesImovelScreen({super.key});

  Future<void> _abrirCanalContato(
      BuildContext context, {
        required Imovel imovel,
        required CanalContato canal,
      }) async {
    final ImovelService service = ImovelServiceMock();

    // 1. Registra o contato na API no momento do disparo
    await service.registrarContato(
      imovelId: imovel.id,
      corretorTelefone: imovel.corretorTelefone,
      canal: canal,
    );

    Uri url;

    switch (canal) {
      case CanalContato.whatsapp:
      // Mensagem pré-formatada montada com código e título
        final texto = Uri.encodeComponent(
          'Olá, tenho interesse no imóvel "${imovel.titulo}" (Código: ${imovel.codigo}). Podemos conversar?',
        );
        url = Uri.parse('https://wa.me/${imovel.corretorTelefone}?text=$texto');
        break;

      case CanalContato.telefone:
        url = Uri.parse('tel:${imovel.corretorTelefone}');
        break;

      case CanalContato.email:
        final assunto = Uri.encodeComponent('Interesse no imóvel ${imovel.codigo}');
        url = Uri.parse('mailto:${imovel.corretorEmail}?subject=$assunto');
        break;
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o aplicativo associado.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imovel = ModalRoute.of(context)?.settings.arguments as Imovel?;

    if (imovel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes')),
        body: const Center(child: Text('Imóvel não encontrado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(imovel.titulo)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(imovel.imagemUrl, height: 220, width: double.infinity, fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text('R\$ ${imovel.preco}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('${imovel.bairro}, ${imovel.cidade}', style: const TextStyle(color: Colors.grey)),
            const Divider(height: 32),

            // Card do Corretor com opções de contato
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Corretor: ${imovel.corretorNome}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Botão WhatsApp Principal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _abrirCanalContato(context, imovel: imovel, canal: CanalContato.whatsapp),
                      icon: const Icon(Icons.chat),
                      label: const Text('Falar no WhatsApp'),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Alternativas (Telefone e E-mail)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _abrirCanalContato(context, imovel: imovel, canal: CanalContato.telefone),
                          icon: const Icon(Icons.phone),
                          label: const Text('Ligar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _abrirCanalContato(context, imovel: imovel, canal: CanalContato.email),
                          icon: const Icon(Icons.email),
                          label: const Text('E-mail'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
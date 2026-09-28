import 'package:flutter/material.dart';
import '../models/imovel.dart';

class ImovelCard extends StatelessWidget {
  final Imovel imovel;
  final VoidCallback onTap;

  const ImovelCard({super.key, required this.imovel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAluguel = imovel.natureza == NaturezaImovel.aluguel;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto de Capa + Badges
              Stack(
                children: [
                  Image.network(
                    imovel.imagemUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.home, size: 50, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAluguel ? Colors.blue.shade700 : Colors.green.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isAluguel ? 'ALUGUEL' : 'VENDA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Conteúdo do Card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      imovel.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${imovel.bairro}, ${imovel.cidade}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAluguel
                              ? 'R\$ ${imovel.preco.toStringAsFixed(0)} /mês'
                              : 'R\$ ${imovel.preco.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.king_bed_outlined, size: 18, color: Colors.grey.shade700),
                            const SizedBox(width: 4),
                            Text('${imovel.quartos}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 12),
                            Icon(Icons.square_foot, size: 18, color: Colors.grey.shade700),
                            const SizedBox(width: 4),
                            Text('${imovel.areaM2.toInt()}m²', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
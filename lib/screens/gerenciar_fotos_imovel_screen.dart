import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/imovel.dart';
import '../models/imovel_detalhe.dart';
import '../services/foto_imovel_service.dart';

class GerenciarFotosImovelScreen extends StatefulWidget {
  final Imovel? imovel;
  final String imovelId;
  final String imovelTitulo;
  final String imovelCodigo;
  final List<FotoImovel> fotosIniciais;

  const GerenciarFotosImovelScreen({
    super.key,
    this.imovel,
    required this.imovelId,
    required this.imovelTitulo,
    required this.imovelCodigo,
    this.fotosIniciais = const [],
  });

  @override
  State<GerenciarFotosImovelScreen> createState() => _GerenciarFotosImovelScreenState();
}

class _GerenciarFotosImovelScreenState extends State<GerenciarFotosImovelScreen> {
  final _fotoService = FotoImovelService();
  final _picker = ImagePicker();

  late List<FotoImovel> _fotos;
  bool _enviando = false;
  FotoUploadProgress? _progresso;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _fotos = List<FotoImovel>.from(widget.fotosIniciais);

    // Se a lista de fotos inicial tiver itens mas nenhuma marcada como capa, define a primeira como capa
    if (_fotos.isNotEmpty && !_fotos.any((f) => f.capa)) {
      _definirCapa(_fotos.first.id);
    }
  }

  Future<void> _capturarDaCamera() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (foto != null) {
        await _enviarFotos([foto]);
      }
    } catch (e) {
      _mostrarMensagemErro('Não foi possível acessar a câmera do dispositivo.');
    }
  }

  Future<void> _selecionarDaGaleria() async {
    try {
      final List<XFile> fotos = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (fotos.isNotEmpty) {
        await _enviarFotos(fotos);
      }
    } catch (e) {
      _mostrarMensagemErro('Não foi possível acessar a galeria de fotos.');
    }
  }

  Future<void> _enviarFotos(List<XFile> arquivos) async {
    setState(() {
      _enviando = true;
      _erro = null;
      _progresso = FotoUploadProgress(enviadas: 0, total: arquivos.length);
    });

    try {
      final novasFotos = await _fotoService.uploadFotosEmLote(
        imovelId: widget.imovelId,
        arquivos: arquivos,
        onProgress: (progresso) {
          if (mounted) {
            setState(() {
              _progresso = progresso;
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _fotos.addAll(novasFotos);
        // Ajusta ordem e capa
        final fotoCapaAtual = _fotos.firstWhere((f) => f.capa, orElse: () => _fotos.first).id;
        _fotos = _fotoService.reorganizarOrdemECapa(_fotos, fotoCapaAtual);
        _enviando = false;
        _progresso = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${novasFotos.length} foto(s) enviada(s) com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _erro = 'Erro durante o envio das fotos. Algumas fotos podem não ter sido enviadas.';
      });
      _mostrarMensagemErro(_erro!);
    }
  }

  Future<void> _excluirFoto(FotoImovel foto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir foto'),
        content: const Text('Tem certeza que deseja apagar esta foto do imóvel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _fotoService.excluirFoto(imovelId: widget.imovelId, fotoId: foto.id);
      if (!mounted) return;

      setState(() {
        _fotos.removeWhere((f) => f.id == foto.id);

        if (_fotos.isNotEmpty && !_fotos.any((f) => f.capa)) {
          _definirCapa(_fotos.first.id);
        } else if (_fotos.isNotEmpty) {
          final idCapa = _fotos.firstWhere((f) => f.capa, orElse: () => _fotos.first).id;
          _fotos = _fotoService.reorganizarOrdemECapa(_fotos, idCapa);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto removida com sucesso.')),
      );
    } catch (e) {
      _mostrarMensagemErro('Não foi possível excluir a foto.');
    }
  }

  void _definirCapa(String fotoId) {
    setState(() {
      _fotos = _fotoService.reorganizarOrdemECapa(_fotos, fotoId);
    });
  }

  void _reordenar(int antigoIndice, int novoIndice) {
    setState(() {
      if (novoIndice > antigoIndice) {
        novoIndice -= 1;
      }
      final item = _fotos.removeAt(antigoIndice);
      _fotos.insert(novoIndice, item);

      final idCapa = _fotos.firstWhere((f) => f.capa, orElse: () => _fotos.first).id;
      _fotos = _fotoService.reorganizarOrdemECapa(_fotos, idCapa);
    });
  }

  void _mostrarMensagemErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red.shade700),
    );
  }

  void _salvarEVoltar() {
    Navigator.pop(context, _fotos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotos do Imóvel'),
        actions: [
          TextButton(
            onPressed: _enviando ? null : _salvarEVoltar,
            child: const Text('Concluir', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cabeçalho com identificação do Imóvel
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Icon(Icons.photo_library_outlined, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.imovelCodigo} - ${widget.imovelTitulo}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_fotos.length} foto(s) cadastrada(s)',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Botões Principais: Câmera e Galeria (Critério 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _enviando ? null : _capturarDaCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Tirar Foto'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _enviando ? null : _selecionarDaGaleria,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeria'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Barra de Progresso durante Upload (Critério 2)
          if (_enviando && _progresso != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Enviando ${_progresso!.enviadas} de ${_progresso!.total} foto(s)...',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                        ),
                        Text(
                          '${(_progresso!.porcentagem * 100).toInt()}%',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _progresso!.porcentagem,
                      backgroundColor: Colors.blue.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ),

          // Mensagem de Alerta de Erro (Critério 2)
          if (_erro != null && !_enviando)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_erro!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),

          // Instruções de Reordenação e Foto de Capa (Critério 3)
          if (_fotos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Arraste os itens para reordenar. Escolha a foto de capa.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),

          // Lista Reordenável de Fotos (Critérios 3 e 4)
          Expanded(
            child: _fotos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('Nenhuma foto cadastrada neste imóvel.'),
                        const SizedBox(height: 4),
                        const Text(
                          'Use os botões acima para adicionar fotos.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _fotos.length,
                    onReorderItem: (oldIndex, newIndex) => _reordenar(oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final foto = _fotos[index];
                      return _cardFoto(foto, index, key: ValueKey(foto.id));
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _cardFoto(FotoImovel foto, int index, {required Key key}) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Ícone de Drag para Reordenação
            const Icon(Icons.drag_handle, color: Colors.grey),
            const SizedBox(width: 12),

            // Imagem Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 70,
                height: 70,
                child: Image.network(
                  foto.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Informações e Capa
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Foto ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (foto.capa) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 12, color: Colors.white),
                              SizedBox(width: 2),
                              Text(
                                'CAPA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (!foto.capa)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _definirCapa(foto.id),
                      icon: const Icon(Icons.star_border, size: 16),
                      label: const Text('Definir como Capa', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),

            // Botão de Excluir Foto (Critério 4)
            IconButton(
              onPressed: () => _excluirFoto(foto),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Apagar foto',
            ),
          ],
        ),
      ),
    );
  }
}

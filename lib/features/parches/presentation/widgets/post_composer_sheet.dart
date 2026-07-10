import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// Borrador de publicación: texto + foto opcional.
class PostDraft {
  const PostDraft({required this.text, this.photoUrl});

  final String text;
  final String? photoUrl;
}

/// Bottom sheet para redactar una publicación con foto opcional.
/// La foto va como URL: el backend guarda `photoUrl` en el post.
/// TODO(backend): cuando exista servicio de storage para subir archivos,
/// cambiar el campo URL por un picker de galería/cámara.
Future<PostDraft?> showPostComposerSheet(
  BuildContext context, {
  required String title,
}) {
  return showModalBottomSheet<PostDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _PostComposerSheet(title: title),
    ),
  );
}

class _PostComposerSheet extends StatefulWidget {
  const _PostComposerSheet({required this.title});

  final String title;

  @override
  State<_PostComposerSheet> createState() => _PostComposerSheetState();
}

class _PostComposerSheetState extends State<_PostComposerSheet> {
  final _text = TextEditingController();
  final _photo = TextEditingController();
  bool _showPhotoField = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() {
      final has = _text.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    // Refresca la vista previa mientras se escribe la URL.
    _photo.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _photo.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    final photo = _photo.text.trim();
    Navigator.of(context).pop(
      PostDraft(text: text, photoUrl: photo.isEmpty ? null : photo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final photoUrl = _photo.text.trim();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.xl),
        ),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outline.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(widget.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _text,
                autofocus: true,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: '¿Cómo va el parche? Comparte el momento…',
                ),
              ),
              // Campo de foto (URL) con vista previa.
              if (_showPhotoField) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _photo,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: 'https://… (URL de la foto)',
                    prefixIcon: const Icon(Icons.link, size: 20),
                    suffixIcon: IconButton(
                      tooltip: 'Quitar foto',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _photo.clear();
                        _showPhotoField = false;
                      }),
                    ),
                  ),
                ),
                if (photoUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: Image.network(
                      photoUrl,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 60,
                        alignment: Alignment.center,
                        color: scheme.outline.withValues(alpha: 0.15),
                        child: Text(
                          'No se pudo cargar la vista previa',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  // Adjuntar foto.
                  IconButton.filledTonal(
                    tooltip: 'Añadir foto',
                    isSelected: _showPhotoField,
                    onPressed: () =>
                        setState(() => _showPhotoField = !_showPhotoField),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _hasText ? _submit : null,
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Publicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

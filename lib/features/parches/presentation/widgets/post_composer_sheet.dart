import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/env.dart';
import '../../../../core/storage/media_upload_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Borrador de publicación: texto + foto opcional.
class PostDraft {
  const PostDraft({required this.text, this.photoUrl});

  final String text;
  final String? photoUrl;
}

/// Bottom sheet para redactar una publicación con foto opcional desde
/// galería, cámara, o pegando una URL.
/// Fotos de galería/cámara se suben a Firebase Storage (única pieza de
/// la app sin backend propio: AlphaECI no tiene servicio de storage).
/// Requiere `flutterfire configure` — ver lib/firebase_options.dart.
/// En DEMO=true no sube nada real: usa una imagen de muestra pública.
Future<PostDraft?> showPostComposerSheet(
  BuildContext context, {
  required String title,
  required String parcheId,
}) {
  return showModalBottomSheet<PostDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _PostComposerSheet(title: title, parcheId: parcheId),
    ),
  );
}

class _PostComposerSheet extends ConsumerStatefulWidget {
  const _PostComposerSheet({required this.title, required this.parcheId});

  final String title;

  /// Parche destino: organiza la ruta en Storage
  /// (posts/{parcheId}/{userId}/...).
  final String parcheId;

  @override
  ConsumerState<_PostComposerSheet> createState() =>
      _PostComposerSheetState();
}

class _PostComposerSheetState extends ConsumerState<_PostComposerSheet> {
  final _text = TextEditingController();
  final _photoUrlField = TextEditingController();
  bool _hasText = false;
  bool _showUrlField = false;

  // Foto elegida de galería/cámara (bytes: funciona igual en móvil/web).
  Uint8List? _pickedBytes;
  String _pickedExt = 'jpg';
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _text.addListener(() {
      final has = _text.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _photoUrlField.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _photoUrlField.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    final ext = _extensionOf(file.name);
    // Validación temprana (tamaño/formato): error claro ANTES de publicar.
    try {
      MediaUploadService.validate(bytes, ext);
    } on MediaValidationException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    setState(() {
      _pickedBytes = bytes;
      _pickedExt = ext;
      _showUrlField = false;
      _photoUrlField.clear();
      _error = null;
    });
  }

  String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return 'jpg';
    final ext = name.substring(dot + 1).toLowerCase();
    return MediaUploadService.allowedExtensions.contains(ext) ? ext : 'jpg';
  }

  /// URL manual válida: http/https con host. Nada de file://, data:, etc.
  bool _isValidManualUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  void _removePhoto() => setState(() {
        _pickedBytes = null;
        _error = null;
      });

  Future<void> _submit() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;

    // Pegaron una URL manual: validar que sea http(s) real antes de usarla.
    final manualUrl = _photoUrlField.text.trim();
    if (_pickedBytes == null && manualUrl.isNotEmpty) {
      if (!_isValidManualUrl(manualUrl)) {
        setState(() =>
            _error = 'La URL no es válida. Debe empezar con http(s)://');
        return;
      }
      Navigator.of(context).pop(PostDraft(text: text, photoUrl: manualUrl));
      return;
    }

    // Sin foto: publicación de solo texto, igual que siempre.
    if (_pickedBytes == null) {
      Navigator.of(context).pop(PostDraft(text: text));
      return;
    }

    // Demo: no hay Firebase real que subir — usar una muestra pública.
    // TODO(firebase-test): quitar `&& !Env.firebaseTest` al eliminar el flag.
    if (Env.demoMode && !Env.firebaseTest) {
      final seed = DateTime.now().microsecondsSinceEpoch;
      Navigator.of(context).pop(
        PostDraft(
          text: text,
          photoUrl: 'https://picsum.photos/seed/demo-$seed/900/540',
        ),
      );
      return;
    }

    // Subir a Firebase Storage y usar la URL pública resultante
    // (downloadURL https — jamás una ruta local file://).
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final userId =
          ref.read(authControllerProvider).session?.userId ?? 'anon';
      final url = await ref.read(mediaUploadServiceProvider).uploadPostImage(
            _pickedBytes!,
            parcheId: widget.parcheId,
            userId: userId,
            ext: _pickedExt,
          );
      if (!mounted) return;
      Navigator.of(context).pop(PostDraft(text: text, photoUrl: url));
    } on MediaValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = 'No se pudo subir la foto. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final manualUrl = _photoUrlField.text.trim();

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
              // ── Vista previa de foto elegida (galería/cámara) ──
              if (_pickedBytes != null) ...[
                const SizedBox(height: 10),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: Image.memory(
                        _pickedBytes!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _RemoveButton(onTap: _removePhoto),
                    ),
                  ],
                ),
                if (Env.demoMode && !Env.firebaseTest) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Modo demo: se publicará con una imagen de muestra '
                    'pública (sin backend de storage aún).',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
              // ── URL manual (alternativa a galería/cámara) ──
              if (_showUrlField && _pickedBytes == null) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _photoUrlField,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: 'https://… (URL de la foto)',
                    prefixIcon: const Icon(Icons.link, size: 20),
                    suffixIcon: IconButton(
                      tooltip: 'Quitar',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _photoUrlField.clear();
                        _showUrlField = false;
                      }),
                    ),
                  ),
                ),
                if (manualUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: Image.network(
                      manualUrl,
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
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: TextStyle(color: scheme.error, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              // ── Acciones para adjuntar foto ──
              if (_pickedBytes == null)
                Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Foto de galería',
                      onPressed: () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Tomar foto',
                      onPressed: () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Pegar URL de foto',
                      isSelected: _showUrlField,
                      onPressed: () =>
                          setState(() => _showUrlField = !_showUrlField),
                      icon: const Icon(Icons.link),
                    ),
                    const Spacer(),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          _uploading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _hasText && !_uploading ? _submit : null,
                      icon: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send, size: 18),
                      label: Text(_uploading ? 'Subiendo…' : 'Publicar'),
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

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, size: 16, color: Colors.white),
      ),
    );
  }
}

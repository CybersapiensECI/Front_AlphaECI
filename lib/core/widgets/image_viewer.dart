import 'package:flutter/material.dart';

/// Visor de imagen a pantalla completa: fondo oscuro, pinch-zoom y
/// arrastre (InteractiveViewer). Se cierra con tap fuera, botón X o back.
void showImageViewer(BuildContext context, String imageUrl) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.88),
    builder: (dialogContext) => _ImageViewer(imageUrl: imageUrl),
  );
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Tap en el fondo cierra.
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
          ),
        ),
        Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(),
                    ),
              errorBuilder: (_, _, _) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No se pudo cargar la imagen',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
        ),
        // Botón cerrar.
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          right: 16,
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'mascot.dart';

/// Popup informativo reutilizable (bienvenidas, ayuda contextual por
/// pantalla): superficie opaca con esquinas redondeadas y entrada
/// animada, igual que el resto de diálogos de la app. Mensaje corto y
/// en tono cercano — nada de jerga técnica — con un único botón de
/// cierre.
Future<void> showInfoPopup(
  BuildContext context, {
  required String title,
  required String message,
  String? stickerAsset,
  IconData icon = Icons.help_outline_rounded,
  String actionLabel = 'Entendido',
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondaryAnimation) => _InfoDialog(
      title: title,
      message: message,
      stickerAsset: stickerAsset,
      icon: icon,
      actionLabel: actionLabel,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final scale = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

class _InfoDialog extends StatelessWidget {
  const _InfoDialog({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.icon,
    this.stickerAsset,
  });

  final String title;
  final String message;
  final String actionLabel;
  final IconData icon;
  final String? stickerAsset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Material(
            color: scheme.surface,
            elevation: 24,
            shadowColor: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (stickerAsset != null)
                    MascotSticker(asset: stickerAsset!, size: 110)
                  else
                    Icon(icon, size: 56, color: scheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/info_popup.dart';
import '../../../../core/widgets/mascot.dart';

/// Layout premium para pantallas de autenticación:
/// fondo con blobs de marca + tarjeta glass centrada + logo con gradiente.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              // Entrada de la tarjeta completa: sube con fade.
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                radius: AppRadii.xl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo oficial (lobo + escudo, sin fondo) con
                    // entrada elástica.
                    Hero(
                      tag: 'app-logo',
                      child: const BrandLogo(size: 120)
                          .animate()
                          .scale(
                            begin: const Offset(0.6, 0.6),
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn(duration: 250.ms),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Título con gradiente.
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppGradients.of(context).createShader(bounds),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    child,
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.06, duration: 450.ms, curve: Curves.easeOutCubic),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso rápido con el estilo de la app: flotante, redondeado, con ícono
/// en burbuja de gradiente — no el snackbar plano de Material.
///
/// Caso especial: los errores de conectividad ("Sin conexión…") no van en
/// snackbar sino en un popup amigable con la mascota, explicando qué pasa
/// y cómo resolverlo (los demás avisos sí son notificaciones rápidas).
void showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final lower = message.toLowerCase();
  final isConnectivity =
      lower.contains('sin conexión') || lower.contains('revisa tu red');
  if (isConnectivity && actionLabel == null) {
    showInfoPopup(
      context,
      title: 'Sin conexión',
      message: 'Parece que no tienes internet en este momento. Revisa tu '
          'red Wi-Fi o tus datos móviles y vuelve a intentarlo.',
      icon: Icons.wifi_off_rounded,
      stickerAsset: AppAssets.stickerConfused,
      actionLabel: 'Entendido',
    );
    return;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      duration: const Duration(seconds: 4),
      content: Builder(builder: (context) {
        return Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.buttonOf(context),
              ),
              child: const Icon(Icons.campaign_rounded,
                  size: 20, color: Colors.white),
            )
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  duration: 450.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      }),
      action: actionLabel != null && onAction != null
          ? SnackBarAction(label: actionLabel, onPressed: onAction)
          : null,
    ));
}

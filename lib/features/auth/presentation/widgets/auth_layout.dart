import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
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

/// Muestra el mensaje de un Failure (o éxito) como SnackBar.
void showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      action: actionLabel != null && onAction != null
          ? SnackBarAction(label: actionLabel, onPressed: onAction)
          : null,
    ));
}

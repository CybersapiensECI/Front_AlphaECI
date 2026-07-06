import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_scaffold.dart';

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
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                radius: AppRadii.xl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo con gradiente de marca.
                    Hero(
                      tag: 'app-logo',
                      child: Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.of(context),
                          boxShadow: AppShadows.glow(
                              theme.colorScheme.primary),
                        ),
                        child: const Icon(Icons.hub_outlined,
                            size: 36, color: Colors.white),
                      ),
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
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Muestra el mensaje de un Failure (o éxito) como SnackBar.
void showAppSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

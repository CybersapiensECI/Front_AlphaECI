import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/design_tokens.dart';
import 'gradient_scaffold.dart';
import 'mascot.dart';

/// Pantalla mostrada mientras se restaura la sesión al arrancar.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo: brillo periódico (interno, loop) + entrada elástica
            // (externa, una vez).
            Hero(
              tag: 'app-logo',
              child: const BrandLogo(size: 96)
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .shimmer(
                    delay: 1200.ms,
                    duration: 1100.ms,
                    color: Colors.white.withValues(alpha: 0.35),
                  )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    duration: 650.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 250.ms),
            ),
            const SizedBox(height: AppSpacing.md),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppGradients.of(context).createShader(bounds),
              child: Text(
                'AlphaECI',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

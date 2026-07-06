import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'gradient_scaffold.dart';

/// Pantalla mostrada mientras se restaura la sesión al arrancar.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GradientScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'app-logo',
              child: Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.of(context),
                  boxShadow: AppShadows.glow(scheme.primary),
                ),
                child:
                    const Icon(Icons.hub_outlined, size: 44, color: Colors.white),
              ),
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

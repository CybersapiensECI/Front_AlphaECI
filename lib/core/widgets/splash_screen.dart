import 'package:flutter/material.dart';

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
            const Hero(
              tag: 'app-logo',
              child: BrandLogo(size: 96),
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

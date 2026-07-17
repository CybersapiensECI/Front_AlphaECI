import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../providers/auth_provider.dart';

/// Se muestra en vez del error genérico cuando el perfil aún no existe
/// (404 de profile-service) porque el usuario nunca terminó el registro
/// tras verificar su OTP. Redirige a completar el registro en vez de dejar
/// al usuario atascado con un error de "Reintentar" que nunca va a resolver
/// nada, porque el perfil sencillamente no existe todavía.
class IncompleteRegistrationView extends ConsumerWidget {
  const IncompleteRegistrationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final email = ref.watch(authControllerProvider).session?.email ?? '';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.person_add_alt_1_outlined,
                  size: 40, color: scheme.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Falta terminar tu registro',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Completa tus datos de perfil para poder usar AlphaECI.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () =>
                  context.push(Routes.completeProfile, extra: email),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Terminar registro'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/mascot.dart';
import '../../domain/entities/mona.dart';
import '../providers/gamification_provider.dart';

/// Colección de monas como ÁLBUM de pegatinas: casillas desbloqueadas a
/// color, en progreso con anillo, y bloqueadas como silueta por descubrir.
/// Pantalla completa (ruta pushed desde Perfil).
class MonasScreen extends StatelessWidget {
  const MonasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Álbum de Monas')),
      body: const MonasBody(),
    );
  }
}

/// Cuerpo del álbum, reutilizable como tab del shell principal.
class MonasBody extends ConsumerWidget {
  const MonasBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monas = ref.watch(myMonasProvider);
    final theme = Theme.of(context);

    return AsyncValueView<UserMonas>(
        value: monas,
        onRetry: () => ref.invalidate(myMonasProvider),
        data: (data) {
          final slots = [
            for (final m in data.unlocked) (_MonaState.unlocked, m),
            for (final m in data.inProgress) (_MonaState.inProgress, m),
            for (final m in data.locked) (_MonaState.locked, m),
          ];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: Breakpoints.contentMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Portada del álbum ─────────────────────
                    FadeSlideIn(
                      child: GlassCard(
                        child: Row(
                          children: [
                            const MascotSticker(
                                asset: AppAssets.stickerApproved, size: 72),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Tu colección',
                                      style: theme.textTheme.titleLarge),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${data.totalUnlocked} de ${data.total} '
                                    'monas · ${data.totalXp} XP',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 10),
                                  AnimatedProgressBar(
                                    value: data.total == 0
                                        ? 0
                                        : data.totalUnlocked / data.total,
                                    height: 8,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ── Casillas del álbum ────────────────────
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns =
                            constraints.maxWidth > 520 ? 4 : 3;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: slots.length,
                          itemBuilder: (context, index) {
                            final (state, mona) = slots[index];
                            return FadeSlideIn(
                              delay: Duration(milliseconds: 40 * index),
                              child: _AlbumSlot(mona: mona, state: state),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
    );
  }
}

enum _MonaState { unlocked, inProgress, locked }

Color _rarityColor(BuildContext context, String? rarity) =>
    switch (rarity) {
      'LEGENDARY' => Colors.amber,
      'EPIC' => Colors.purpleAccent,
      'RARE' => Theme.of(context).colorScheme.tertiary,
      _ => Theme.of(context).colorScheme.outline,
    };

/// Casilla del álbum. Tap: detalle de la mona.
class _AlbumSlot extends StatelessWidget {
  const _AlbumSlot({required this.mona, required this.state});

  final Mona mona;
  final _MonaState state;

  void _showDetail(BuildContext context) {
    final theme = Theme.of(context);
    final rarityColor = _rarityColor(context, mona.rarity);
    final locked = state == _MonaState.locked;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              locked ? Icons.lock_outline : Icons.emoji_events,
              color: locked ? theme.colorScheme.outline : rarityColor,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(locked ? '???' : mona.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locked
                  ? 'Sigue participando en la ECI para descubrir esta mona.'
                  : mona.description ?? 'Logro de la comunidad AlphaECI.',
            ),
            const SizedBox(height: 12),
            if (state == _MonaState.inProgress &&
                mona.progressPercentage != null) ...[
              AnimatedProgressBar(
                  value: mona.progressPercentage! / 100, height: 8),
              const SizedBox(height: 6),
              Text(
                '${mona.currentCount ?? 0}/${mona.requiredCount ?? 0} · '
                '${mona.progressPercentage}%',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
            ],
            Text('+${mona.xpGranted} XP',
                style: theme.textTheme.labelLarge),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rarityColor = _rarityColor(context, mona.rarity);
    final locked = state == _MonaState.locked;

    return BouncyTap(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          gradient: locked
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    rarityColor.withValues(alpha: 0.55),
                    rarityColor.withValues(alpha: 0.15),
                  ],
                ),
          color: locked ? scheme.surface : null,
          border: Border.all(
            color: locked
                ? scheme.outline.withValues(alpha: 0.4)
                : rarityColor.withValues(alpha: 0.7),
            width: locked ? 1 : 2,
          ),
          boxShadow: locked ? null : AppShadows.soft(context),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícono de la pegatina (anillo de progreso si aplica).
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (state == _MonaState.inProgress)
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: (mona.progressPercentage ?? 0) / 100,
                      ),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) =>
                          CircularProgressIndicator(
                        value: value,
                        strokeWidth: 4,
                        backgroundColor:
                            scheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  Icon(
                    locked
                        ? Icons.question_mark
                        : state == _MonaState.inProgress
                            ? Icons.hourglass_bottom
                            : Icons.emoji_events,
                    size: 30,
                    color: locked
                        ? scheme.outline
                        : state == _MonaState.unlocked
                            ? Colors.white
                            : rarityColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              locked ? '???' : mona.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: locked
                    ? scheme.onSurfaceVariant
                    : state == _MonaState.unlocked
                        ? Colors.white
                        : scheme.onSurface,
              ),
            ),
            if (!locked && mona.rarity != null) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: state == _MonaState.unlocked
                      ? Colors.white.withValues(alpha: 0.25)
                      : rarityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mona.rarity!,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: state == _MonaState.unlocked
                        ? Colors.white
                        : rarityColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

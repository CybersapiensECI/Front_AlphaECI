import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../../domain/entities/match.dart';
import '../providers/matching_provider.dart';
import '../widgets/swipe_deck.dart';

/// Descubrir personas: mazo swipeable con score de afinidad.
class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final _deckKey = GlobalKey<SwipeDeckState<DiscoveryCandidate>>();

  Future<void> _like(DiscoveryCandidate candidate) async {
    final result =
        await ref.read(discoveryProvider.notifier).like(candidate);
    if (!mounted) return;
    result.when(
      success: (match) {
        if (match.status == MatchStatus.accepted) {
          _showMatchOverlay(candidate);
        } else {
          showMascotSnackBar(
              context, 'Solicitud enviada a ${candidate.profile.name} 🚀', AppAssets.stickerCool);
        }
      },
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  void _showMatchOverlay(DiscoveryCandidate candidate) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'match',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 420),
      transitionBuilder: (context, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.elasticOut);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, _, _) => _MatchOverlay(candidate: candidate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(discoveryProvider);
    final theme = Theme.of(context);

    return AsyncValueView<List<DiscoveryCandidate>>(
      value: deck,
      onRetry: () => ref.invalidate(discoveryProvider),
      data: (candidates) {
        if (candidates.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const EmptyState(
                icon: Icons.explore_outlined,
                message:
                    'No hay más personas por ahora.\nAgrega intereses a tu '
                    'perfil para mejorar tus recomendaciones.',
              ),
              TextButton.icon(
                onPressed: () => ref.invalidate(discoveryProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Buscar de nuevo'),
              ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 400, maxHeight: 540),
                    child: SwipeDeck<DiscoveryCandidate>(
                      key: _deckKey,
                      items: candidates,
                      onLike: _like,
                      onSkip: (c) =>
                          ref.read(discoveryProvider.notifier).skip(c),
                      cardBuilder: (context, candidate) =>
                          _CandidateCard(candidate: candidate),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Botones de acción.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    icon: Icons.close,
                    color: Colors.redAccent,
                    tooltip: 'Pasar',
                    onPressed: () =>
                        _deckKey.currentState?.triggerSwipe(right: false),
                  ),
                  const SizedBox(width: 32),
                  _ActionButton(
                    icon: Icons.favorite,
                    color: theme.colorScheme.primary,
                    tooltip: 'Conectar',
                    big: true,
                    onPressed: () =>
                        _deckKey.currentState?.triggerSwipe(right: true),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate});

  final DiscoveryCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final scored = candidate.scored;
    final percent = (scored.totalScore * 100).clamp(0, 100).round();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con gradiente de marca y avatar superpuesto.
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 88,
                  width: double.infinity,
                  decoration:
                      BoxDecoration(gradient: AppGradients.of(context)),
                ),
                Positioned(
                  bottom: -44,
                  child: ProfileAvatar(
                    name: candidate.profile.name,
                    photoUrl: candidate.profile.photoUrl,
                    radius: 44,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 56),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
            Text(
              candidate.profile.name,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (candidate.profile.biography?.isNotEmpty == true)
              Text(
                candidate.profile.biography!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 20),
            // Afinidad total con anillo animado.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: scored.totalScore.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 7,
                      backgroundColor: scheme.outline.withValues(alpha: 0.25),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(scheme.tertiary),
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text('afinidad', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            // Desglose de scores.
            _ScoreRow(label: 'Intereses', value: scored.interestScore),
            _ScoreRow(label: 'Académico', value: scored.academicScore),
            _ScoreRow(label: 'Horario', value: scored.scheduleScore),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: AnimatedProgressBar(value: value.clamp(0.0, 1.0), height: 6),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
    this.big = false,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onPressed,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: big ? 68 : 56,
          height: big ? 68 : 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: big ? 34 : 28),
        ),
      ),
    );
  }
}

class _MatchOverlay extends StatelessWidget {
  const _MatchOverlay({required this.candidate});

  final DiscoveryCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: GlassCard(
              radius: AppRadii.xl,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MascotSticker(stickerIndex: AppAssets.stickerLove, size: 84),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.of(context),
                          boxShadow:
                              AppShadows.glow(theme.colorScheme.tertiary),
                        ),
                        child: ProfileAvatar(
                          name: candidate.profile.name,
                          photoUrl: candidate.profile.photoUrl,
                          radius: 44,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppGradients.of(context).createShader(bounds),
                    child: Text(
                      '¡Conectaron!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tú y ${candidate.profile.name} quieren conectar.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: '¡Genial!',
                    icon: Icons.celebration_outlined,
                    onPressed: () => Navigator.of(context).pop(),
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

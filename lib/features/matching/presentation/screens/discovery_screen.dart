import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../../../auth/presentation/widgets/incomplete_registration_view.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
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
      error: _handleMatchError,
    );
  }

  /// failure.message ya viene traducido a español (ver
  /// backend_message_translator.dart) — acá solo se decide si además hay
  /// que guiar al usuario a completar el dato que falta.
  void _handleMatchError(Failure failure) {
    final message = failure.message;
    final guideToProfile = message.contains('Agrega al menos un interés') ||
        message.contains('Agrega tu horario');
    showAppSnackBar(
      context,
      message,
      actionLabel: guideToProfile ? 'Editar perfil' : null,
      onAction:
          guideToProfile ? () => context.push(Routes.editProfile) : null,
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
    // Si nunca se terminó el registro (perfil 404 en profile-service), no
    // tiene sentido pedirle recomendaciones a matching-service: guiar
    // directo a terminar el registro en vez de mostrar un error crudo.
    final myProfile = ref.watch(myProfileProvider);
    if (myProfile.hasError && myProfile.error is NotFoundFailure) {
      return const IncompleteRegistrationView();
    }

    final deck = ref.watch(discoveryProvider);
    final theme = Theme.of(context);

    return AsyncValueView<List<DiscoveryCandidate>>(
      value: deck,
      onRetry: () => ref.invalidate(discoveryProvider),
      errorBuilder: (failure) => failure is NotFoundFailure
          ? const IncompleteRegistrationView()
          : null,
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
      // Opaca a propósito: en el mazo apilado, una carta translúcida
      // dejaría ver las de atrás y el fondo, impidiendo leer la info.
      color: scheme.surface,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.28),
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

class _MatchOverlay extends ConsumerWidget {
  const _MatchOverlay({required this.candidate});

  final DiscoveryCandidate candidate;

  /// Avatar con anillo de gradiente de marca (una persona del match).
  Widget _avatarRing(BuildContext context, {String? name, String? photoUrl}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.of(context),
        boxShadow: AppShadows.glow(Theme.of(context).colorScheme.tertiary),
      ),
      child: ProfileAvatar(
        name: name ?? 'Tú',
        photoUrl: photoUrl,
        radius: 44,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(myProfileProvider).valueOrNull;
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
                  // Composición simétrica: los dos perfiles arriba y el
                  // sticker de conexión centrado abajo, entre ambos.
                  SizedBox(
                    height: 170,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cada perfil entra deslizando desde su lado.
                            _avatarRing(
                              context,
                              name: me?.name,
                              photoUrl: me?.photoUrl,
                            )
                                .animate()
                                .slideX(
                                  begin: -0.8,
                                  duration: 450.ms,
                                  curve: Curves.easeOutCubic,
                                )
                                .fadeIn(duration: 250.ms),
                            _avatarRing(
                              context,
                              name: candidate.profile.name,
                              photoUrl: candidate.profile.photoUrl,
                            )
                                .animate()
                                .slideX(
                                  begin: 0.8,
                                  duration: 450.ms,
                                  curve: Curves.easeOutCubic,
                                )
                                .fadeIn(duration: 250.ms),
                          ],
                        ),
                        // El sticker de conexión aparece al final, con pop.
                        Positioned(
                          bottom: 0,
                          child: const MascotSticker(
                            asset: AppAssets.stickerLove,
                            size: 96,
                          )
                              .animate()
                              .scale(
                                begin: const Offset(0.2, 0.2),
                                delay: 350.ms,
                                duration: 550.ms,
                                curve: Curves.elasticOut,
                              )
                              .fadeIn(delay: 350.ms, duration: 150.ms),
                        ),
                      ],
                    ),
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
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 300.ms)
                      .shimmer(delay: 800.ms, duration: 900.ms),
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

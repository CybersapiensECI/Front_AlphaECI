import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/info_popup.dart';
import '../../../../core/widgets/mascot.dart';
import '../../domain/entities/mona.dart';
import '../providers/gamification_provider.dart';
import '../widgets/mona_medal.dart';
import '../widgets/mona_styles.dart';

/// Texto de ayuda de esta pantalla, en tono cercano y sin jerga técnica.
/// Compartido entre la AppBar propia de [MonasScreen] y la AppBar del
/// shell principal (home_screen.dart) cuando Monas es un tab.
const monasHelpTitle = 'Monas';
const monasHelpMessage = 'Es tu álbum de logros: ve ganando monas al '
    'participar en parches y eventos de la comunidad. Toca cualquier '
    'casilla para verla de cerca.';

/// Colección de monas como ÁLBUM de pegatinas: casillas desbloqueadas a
/// color, en progreso con anillo, y bloqueadas como silueta por descubrir.
/// Pantalla completa (ruta pushed desde Perfil).
class MonasScreen extends StatelessWidget {
  const MonasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Álbum de Monas'),
        actions: [
          IconButton(
            tooltip: 'Ayuda',
            onPressed: () => showInfoPopup(
              context,
              title: monasHelpTitle,
              message: monasHelpMessage,
            ),
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
      body: const MonasBody(),
    );
  }
}

/// Cuerpo del álbum, reutilizable como tab del shell principal.
class MonasBody extends ConsumerStatefulWidget {
  const MonasBody({super.key});

  @override
  ConsumerState<MonasBody> createState() => _MonasBodyState();
}

class _MonasBodyState extends ConsumerState<MonasBody> {
  @override
  void initState() {
    super.initState();
    // Popup de bienvenida solo la primera vez que se abre esta pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowWelcome());
  }

  Future<void> _maybeShowWelcome() async {
    final storage = ref.read(onboardingStorageProvider);
    if (await storage.hasSeenMonasWelcome()) return;
    await storage.markMonasWelcomeSeen();
    if (!mounted) return;
    showInfoPopup(
      context,
      title: '¡Bienvenido a tu Álbum de Monas!',
      message: 'Aquí coleccionas las monas que desbloqueas al participar '
          'en parches, eventos y retos de la comunidad. Cada una suma XP '
          'a tu perfil — ¡sigue explorando para completar el álbum!',
      stickerAsset: AppAssets.stickerCool,
      actionLabel: '¡Vamos!',
    );
  }

  @override
  Widget build(BuildContext context) {
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
                maxWidth: Breakpoints.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Portada del álbum ─────────────────────
                  FadeSlideIn(
                    child: GlassCard(
                      child: Row(
                        children: [
                          const MascotSticker(
                            asset: AppAssets.stickerApproved,
                            size: 72,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Tu colección',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${data.totalUnlocked} de ${data.total} '
                                  'monas · ${data.totalXp} XP',
                                  textAlign: TextAlign.center,
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
                      final columns = constraints.maxWidth > 520 ? 4 : 3;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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

/// Abre el detalle de una mona en un diálogo 100% opaco (sin glassmorphism)
/// con entrada animada (pop elástico) y banner metálico por categoría.
Future<void> _showMonaDetail(
  BuildContext context,
  Mona mona,
  _MonaState state,
) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar detalle de mona',
    barrierColor: Colors.black.withValues(alpha: 0.62),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _MonaDetailDialog(mona: mona, state: state),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final scale = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

/// Detalle de una mona: tarjeta volteable. Cara frontal = medalla (arte
/// real); al tocar o deslizar se voltea y muestra la descripción.
/// Superficie 100% opaca (sin transparencia) en ambas caras.
class _MonaDetailDialog extends StatelessWidget {
  const _MonaDetailDialog({required this.mona, required this.state});

  final Mona mona;
  final _MonaState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final category = monaCategoryOf(mona);
    final rarityColor = monaRarityColor(mona.rarity);
    final rarityGradient = monaRarityGradient(mona.rarity);
    final rarityLabel = monaRarityLabel(mona.rarity);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Material(
            // Superficie 100% opaca: NO usa el DialogTheme translúcido global.
            color: scheme.surface,
            elevation: 24,
            shadowColor: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 600,
              child: Stack(
                children: [
                  _FlipCard(
                    front: _MonaMedalFace(
                      mona: mona,
                      state: state,
                      category: category,
                      rarityGradient: rarityGradient,
                    ),
                    back: _MonaDescriptionFace(
                      mona: mona,
                      state: state,
                      rarityColor: rarityColor,
                      rarityGradient: rarityGradient,
                      rarityLabel: rarityLabel,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black.withValues(alpha: 0.22),
                      ),
                    ),
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

/// Tarjeta que se voltea sobre el eje Y al tocarla o deslizarla hacia un
/// lado. Muestra [front] o [back] según el ángulo de rotación actual.
class _FlipCard extends StatefulWidget {
  const _FlipCard({required this.front, required this.back});

  final Widget front;
  final Widget back;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  bool _showingFront = true;

  void _flip() {
    if (_showingFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _showingFront = !_showingFront);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if ((details.primaryVelocity ?? 0).abs() > 120) _flip();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final angle = _controller.value * math.pi;
          final showBack = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(showBack ? angle - math.pi : angle),
            child: showBack ? widget.back : widget.front,
          );
        },
      ),
    );
  }
}

/// Cara frontal: la medalla — arte real de la mona en un marco metálico
/// de categoría. Bloqueada: imagen atenuada + cadenas y candado.
class _MonaMedalFace extends StatelessWidget {
  const _MonaMedalFace({
    required this.mona,
    required this.state,
    required this.category,
    required this.rarityGradient,
  });

  final Mona mona;
  final _MonaState state;
  final String category;
  final List<Color> rarityGradient;

  @override
  Widget build(BuildContext context) {
    final locked = state == _MonaState.locked;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: locked
              ? [for (final c in rarityGradient) c.withValues(alpha: 0.35)]
              : rarityGradient,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // La medalla: el arte real de la mona, tan grande como el
          // espacio disponible, sin marco añadido.
          Expanded(
            child: SizedBox.expand(
              child: MonaMedal(
                mona: mona,
                locked: locked,
                fallbackIcon: monaCategoryIcon(category),
                iconSize: 128,
                lockBadgeSize: 44,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mona.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cara trasera: descripción, progreso y XP — superficie opaca lisa para
/// máxima legibilidad del texto.
class _MonaDescriptionFace extends StatelessWidget {
  const _MonaDescriptionFace({
    required this.mona,
    required this.state,
    required this.rarityColor,
    required this.rarityGradient,
    required this.rarityLabel,
  });

  final Mona mona;
  final _MonaState state;
  final Color rarityColor;
  final List<Color> rarityGradient;
  final String rarityLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 20),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (rarityLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: rarityGradient,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppShadows.glow(rarityColor),
                      ),
                      child: Text(
                        rarityLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 2),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    mona.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    mona.description ?? 'Logro de la comunidad AlphaECI.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (mona.progressPercentage != null) ...[
                    const SizedBox(height: 16),
                    AnimatedProgressBar(
                      value: mona.progressPercentage! / 100,
                      height: 8,
                      color: rarityColor,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${mona.currentCount ?? 0}/'
                      '${mona.requiredCount ?? 0} · '
                      '${mona.progressPercentage}% para obtenerla',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: rarityGradient,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppShadows.glow(rarityColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 2),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${mona.xpGranted} XP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.swipe_rounded,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Toca o desliza para ver la medalla',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Casilla del álbum. Tap: detalle de la mona.
class _AlbumSlot extends StatelessWidget {
  const _AlbumSlot({required this.mona, required this.state});

  final Mona mona;
  final _MonaState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = state == _MonaState.locked;
    final category = monaCategoryOf(mona);
    final rarityColor = monaRarityColor(mona.rarity);
    final progress = mona.progressPercentage;

    // La medalla ES la mona: sin tarjeta rectangular detrás. Solo el
    // nombre debajo. El anillo de progreso (si aplica) y las cadenas
    // (si está bloqueada) viven directamente sobre la medalla.
    Widget medal = MonaMedal(
      mona: mona,
      locked: locked,
      fallbackIcon: state == _MonaState.inProgress
          ? Icons.hourglass_bottom
          : monaCategoryIcon(category),
      iconSize: 56,
      lockBadgeSize: locked ? 22 : null,
    );

    if (progress != null) {
      medal = Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress / 100),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 3,
                backgroundColor: theme.colorScheme.outline.withValues(
                  alpha: 0.2,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(rarityColor),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(10), child: medal),
        ],
      );
    }

    if (state == _MonaState.unlocked) {
      medal = PulseGlow(
        color: rarityColor,
        borderRadius: BorderRadius.circular(999),
        child: medal,
      );
    }

    return BouncyTap(
      onTap: () => _showMonaDetail(context, mona, state),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: medal),
          const SizedBox(height: 6),
          Text(
            mona.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

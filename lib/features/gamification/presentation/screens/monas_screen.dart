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
import '../widgets/locked_overlay.dart';
import '../widgets/mona_styles.dart';

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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tu colección',
                                  style: theme.textTheme.titleLarge,
                                ),
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
                      final columns = constraints.maxWidth > 520 ? 4 : 3;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          // 0.68: alto suficiente para medalla + nombre a
                          // 2 líneas + badge de % (0.78 desbordaba ~5px).
                          childAspectRatio: 0.68,
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

/// Detalle de una mona: superficie opaca (sin transparencia), banner
/// metálico animado según categoría y micro-animaciones de entrada.
class _MonaDetailDialog extends StatelessWidget {
  const _MonaDetailDialog({required this.mona, required this.state});

  final Mona mona;
  final _MonaState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locked = state == _MonaState.locked;
    final category = monaCategoryOf(mona);
    final metallic = monaCategoryMetallic(category);
    final rarityColor = monaRarityColor(mona.rarity);
    final rarityGradient = monaRarityGradient(mona.rarity);
    final rarityLabel = monaRarityLabel(mona.rarity);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Material(
            // Superficie 100% opaca: NO usa el DialogTheme translúcido global.
            color: scheme.surface,
            elevation: 24,
            shadowColor: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Fondo del banner = gradiente metálico de rareza
                      // (Hierro/Bronce/Plata/Amatista/Oro). El brillo lo
                      // da el propio degradado, sin animación de shine.
                      // Bloqueada: mismo degradado pero atenuado + cadenas.
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: locked
                                  ? [
                                      for (final c in rarityGradient)
                                        c.withValues(alpha: 0.4),
                                    ]
                                  : rarityGradient,
                            ),
                          ),
                        ),
                      ),
                      if (locked) const Positioned.fill(child: ChainsOverlay()),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.18,
                            ),
                          ),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) => Transform.rotate(
                          angle: (1 - value.clamp(0.0, 1.0)) * 0.8,
                          child: Transform.scale(scale: value, child: child),
                        ),
                        // Medalla del ícono: aquí vive el metalizado de
                        // categoría (independiente del color general).
                        child: ClipOval(
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: locked ? kChainSteel : metallic,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha: locked ? 0.7 : 0.9,
                                ),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              locked
                                  ? Icons.lock_rounded
                                  : state == _MonaState.inProgress
                                  ? Icons.hourglass_bottom
                                  : monaCategoryIcon(category),
                              size: 36,
                              color: locked
                                  ? const Color(0xFF2B2F36)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rareza: texto visible solo aquí, en el detalle.
                      if (!locked && rarityLabel.isNotEmpty)
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 90),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) =>
                                Transform.scale(scale: value, child: child),
                            child: Container(
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
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      // Nombre y descripción siempre visibles, aunque la
                      // mona esté bloqueada: solo el arte queda encadenado.
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: Text(
                          mona.name,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          mona.description ?? 'Logro de la comunidad AlphaECI.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
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
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 260),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 650),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) => Transform.scale(
                            scale: value.clamp(0.0, 1.4),
                            child: child,
                          ),
                          child: Container(
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
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '+${mona.xpGranted} XP',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
    final metallic = monaCategoryMetallic(category);
    final rarityColor = monaRarityColor(mona.rarity);
    final rarityGradient = monaRarityGradient(mona.rarity);

    final progress = mona.progressPercentage;

    // Color general de la mona = gradiente metálico de rareza (vivo,
    // incluso bloqueada — solo atenuado). El metalizado de categoría
    // queda reservado a la medalla del ícono (o el acero del candado).
    final tile = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.md),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: state == _MonaState.unlocked
              ? rarityGradient
              : [
                  for (final c in rarityGradient)
                    c.withValues(alpha: locked ? 0.28 : 0.42),
                ],
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: state == _MonaState.unlocked ? 0.55 : 0.3,
          ),
          width: state == _MonaState.unlocked ? 2 : 1.4,
        ),
        boxShadow: [
          ...AppShadows.soft(context),
          if (state == _MonaState.unlocked) ...AppShadows.glow(rarityColor),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          if (locked) const Positioned.fill(child: ChainsOverlay()),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono de la pegatina (anillo de progreso si aplica).
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (progress != null)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress / 100),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) =>
                            CircularProgressIndicator(
                              value: value,
                              strokeWidth: 4,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.25,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                rarityColor,
                              ),
                            ),
                      ),
                    // Medalla metálica: categoría, o acero si está
                    // bloqueada (el material del candado).
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: locked ? kChainSteel : metallic,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        locked
                            ? Icons.lock_rounded
                            : state == _MonaState.inProgress
                            ? Icons.hourglass_bottom
                            : monaCategoryIcon(category),
                        size: 24,
                        color: locked ? const Color(0xFF2B2F36) : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Nombre real siempre visible: solo el arte queda encadenado.
              // Flexible: si el alto no alcanza (fuentes grandes), el texto
              // cede con ellipsis en vez de desbordar la casilla.
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    mona.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$progress%',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    // Desbloqueadas: resplandor pulsante (sin animar el metal en sí).
    final decorated = state == _MonaState.unlocked
        ? PulseGlow(
            color: rarityColor,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: tile,
          )
        : tile;

    return BouncyTap(
      onTap: () => _showMonaDetail(context, mona, state),
      child: decorated,
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Shimmer propio sin dependencias: gradiente que se desliza en loop.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            scheme.outline.withValues(alpha: 0.15),
            scheme.outline.withValues(alpha: 0.35),
            scheme.outline.withValues(alpha: 0.15),
          ],
          stops: const [0.25, 0.5, 0.75],
          transform:
              _SlidingGradientTransform(percent: _controller.value),
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.percent});

  final double percent;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
        bounds.width * (percent * 2 - 1), 0, 0);
  }
}

/// Caja base del skeleton.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = AppRadii.sm,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton de card de feed (parches/eventos).
class SkeletonFeedCard extends StatelessWidget {
  const SkeletonFeedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                SkeletonBox(width: 44, height: 44, radius: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 160, height: 14),
                      SizedBox(height: 6),
                      SkeletonBox(width: 90, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const SkeletonBox(height: 12),
            const SizedBox(height: 6),
            const SkeletonBox(width: 220, height: 12),
            const SizedBox(height: 14),
            const SkeletonBox(height: 8, radius: 4),
          ],
        ),
      ),
    );
  }
}

/// Lista de skeletons con shimmer, lista para AsyncValueView.loading.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.maxWidth = 720});

  final int count;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: count,
        itemBuilder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: const SkeletonFeedCard(),
          ),
        ),
      ),
    );
  }
}

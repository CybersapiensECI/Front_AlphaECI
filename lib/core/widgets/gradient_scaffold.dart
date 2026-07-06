import 'package:flutter/material.dart';

/// Fondo con "blobs" radiales de marca que flotan lentamente.
/// Barato: solo gradientes radiales + una animación de 20s, sin filtros.
class FloatingBlobBackground extends StatefulWidget {
  const FloatingBlobBackground({super.key, required this.child});

  final Widget child;

  @override
  State<FloatingBlobBackground> createState() =>
      _FloatingBlobBackgroundState();
}

class _FloatingBlobBackgroundState extends State<FloatingBlobBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alpha = isDark ? 0.20 : 0.14;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Stack(
              children: [
                _Blob(
                  alignment: Alignment(-1.2 + 0.3 * t, -1.1 + 0.2 * t),
                  color: scheme.primary.withValues(alpha: alpha),
                  size: 420,
                ),
                _Blob(
                  alignment: Alignment(1.3 - 0.25 * t, -0.2 + 0.3 * t),
                  color: scheme.tertiary.withValues(alpha: alpha),
                  size: 360,
                ),
                _Blob(
                  alignment: Alignment(-0.3 + 0.2 * t, 1.3 - 0.2 * t),
                  color: scheme.secondary.withValues(alpha: alpha * 0.8),
                  size: 380,
                ),
              ],
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.alignment,
    required this.color,
    required this.size,
  });

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Scaffold con fondo de blobs de marca. Reemplazo directo de Scaffold
/// para pantallas que quieran el fondo premium.
class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBody = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    return FloatingBlobBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        extendBody: extendBody,
      ),
    );
  }
}

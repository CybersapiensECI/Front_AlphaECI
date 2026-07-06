import 'package:flutter/material.dart';

/// Fondo con "blobs" radiales de marca que flotan lentamente y REACCIONAN
/// al usuario: se inclinan sutilmente hacia el dedo/puntero y emiten un
/// pulso suave al tocar. Barato: gradientes radiales + 2 controllers,
/// sin filtros ni shaders.
class FloatingBlobBackground extends StatefulWidget {
  const FloatingBlobBackground({super.key, required this.child});

  final Widget child;

  @override
  State<FloatingBlobBackground> createState() =>
      _FloatingBlobBackgroundState();
}

class _FloatingBlobBackgroundState extends State<FloatingBlobBackground>
    with TickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat(reverse: true);

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  /// Posición del puntero en coordenadas Alignment (-1..1).
  /// Se interpola en cada frame del drift: reacción suave, sin jank.
  Alignment _pointerTarget = Alignment.center;
  Alignment _pointer = Alignment.center;

  @override
  void dispose() {
    _drift.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _updatePointer(Offset position, Size size) {
    _pointerTarget = Alignment(
      (position.dx / size.width) * 2 - 1,
      (position.dy / size.height) * 2 - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alpha = isDark ? 0.20 : 0.14;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerHover: (e) => _updatePointer(e.localPosition, size),
          onPointerMove: (e) => _updatePointer(e.localPosition, size),
          onPointerDown: (e) {
            _updatePointer(e.localPosition, size);
            _pulse.forward(from: 0);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
              AnimatedBuilder(
                animation: Listenable.merge([_drift, _pulse]),
                builder: (context, _) {
                  final t = _drift.value;
                  // Persecución suave del puntero (lerp por frame).
                  _pointer =
                      Alignment.lerp(_pointer, _pointerTarget, 0.06)!;
                  // Pulso al tocar: crece y se desvanece (curva campana).
                  final p = _pulse.isAnimating
                      ? Curves.easeOut.transform(_pulse.value)
                      : 0.0;
                  final pulseScale = 1 + 0.10 * (1 - p) * (p > 0 ? 1 : 0);

                  Alignment follow(Alignment base, double strength) =>
                      Alignment(
                        base.x + (_pointer.x - base.x) * strength,
                        base.y + (_pointer.y - base.y) * strength,
                      );

                  return Stack(
                    children: [
                      _Blob(
                        alignment: follow(
                          Alignment(-1.2 + 0.3 * t, -1.1 + 0.2 * t),
                          0.18,
                        ),
                        color: scheme.primary.withValues(alpha: alpha),
                        size: 420 * pulseScale,
                      ),
                      _Blob(
                        alignment: follow(
                          Alignment(1.3 - 0.25 * t, -0.2 + 0.3 * t),
                          0.26,
                        ),
                        color: scheme.tertiary.withValues(alpha: alpha),
                        size: 360 * pulseScale,
                      ),
                      _Blob(
                        alignment: follow(
                          Alignment(-0.3 + 0.2 * t, 1.3 - 0.2 * t),
                          0.12,
                        ),
                        color:
                            scheme.secondary.withValues(alpha: alpha * 0.8),
                        size: 380,
                      ),
                    ],
                  );
                },
              ),
              widget.child,
            ],
          ),
        );
      },
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

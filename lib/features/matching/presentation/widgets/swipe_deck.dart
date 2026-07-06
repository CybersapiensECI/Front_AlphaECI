import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Mazo de cards deslizables estilo app de matching.
/// Arrastra derecha = like, izquierda = skip. Con rotación proporcional
/// al arrastre y animación de salida.
class SwipeDeck<T> extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.items,
    required this.cardBuilder,
    required this.onLike,
    required this.onSkip,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) cardBuilder;
  final void Function(T item) onLike;
  final void Function(T item) onSkip;

  @override
  State<SwipeDeck<T>> createState() => SwipeDeckState<T>();
}

class SwipeDeckState<T> extends State<SwipeDeck<T>>
    with SingleTickerProviderStateMixin {
  Offset _drag = Offset.zero;
  late final AnimationController _exitController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  Animation<Offset>? _exitAnimation;
  bool _exitingRight = false;
  bool _animatingOut = false;

  static const _threshold = 90.0;

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  /// Dispara el swipe desde los botones (like/nope).
  void triggerSwipe({required bool right}) {
    if (widget.items.isEmpty || _animatingOut) return;
    _animateOut(right);
  }

  void _animateOut(bool right) {
    final width = MediaQuery.sizeOf(context).width;
    _exitingRight = right;
    _animatingOut = true;
    _exitAnimation = Tween<Offset>(
      begin: _drag,
      end: Offset(right ? width * 1.2 : -width * 1.2, _drag.dy - 40),
    ).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );
    _exitController.forward(from: 0).whenComplete(() {
      final item = widget.items.first;
      setState(() {
        _drag = Offset.zero;
        _animatingOut = false;
        _exitAnimation = null;
      });
      _exitingRight ? widget.onLike(item) : widget.onSkip(item);
    });
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (_drag.dx > _threshold) {
      _animateOut(true);
    } else if (_drag.dx < -_threshold) {
      _animateOut(false);
    } else {
      // Vuelve al centro con rebote.
      setState(() => _drag = Offset.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final visible = widget.items.take(3).toList();

    return AnimatedBuilder(
      animation: _exitController,
      builder: (context, _) {
        final offset =
            _animatingOut ? (_exitAnimation?.value ?? _drag) : _drag;
        final rotation = (offset.dx / 300).clamp(-1.0, 1.0) * 0.18;
        final likeOpacity = (offset.dx / _threshold).clamp(0.0, 1.0);
        final nopeOpacity = (-offset.dx / _threshold).clamp(0.0, 1.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Cards de atrás (escala/offset decreciente).
            for (var i = visible.length - 1; i >= 1; i--)
              Transform.translate(
                offset: Offset(0, 12.0 * i),
                child: Transform.scale(
                  scale: 1 - 0.04 * i,
                  child: IgnorePointer(
                    child: widget.cardBuilder(context, visible[i]),
                  ),
                ),
              ),
            // Card frontal arrastrable.
            GestureDetector(
              onPanUpdate: _animatingOut
                  ? null
                  : (d) => setState(() => _drag += d.delta),
              onPanEnd: _animatingOut ? null : _onPanEnd,
              child: Transform.translate(
                offset: offset,
                child: Transform.rotate(
                  angle: rotation,
                  child: Stack(
                    children: [
                      widget.cardBuilder(context, visible.first),
                      // Sellos LIKE / NOPE.
                      Positioned(
                        top: 24,
                        left: 20,
                        child: _Stamp(
                          label: 'CONECTAR',
                          color: Colors.green,
                          opacity: likeOpacity,
                          angle: -math.pi / 12,
                        ),
                      ),
                      Positioned(
                        top: 24,
                        right: 20,
                        child: _Stamp(
                          label: 'PASO',
                          color: Colors.redAccent,
                          opacity: nopeOpacity,
                          angle: math.pi / 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.label,
    required this.color,
    required this.opacity,
    required this.angle,
  });

  final String label;
  final Color color;
  final double opacity;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

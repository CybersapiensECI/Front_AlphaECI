import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Acabado "acero" del candado/cadenas — es el material del cierre, no
/// de la mona en sí (independiente de categoría y rareza).
const List<Color> kChainSteel = [
  Color(0xFFF1F4F7),
  Color(0xFFB9C2CC),
  Color(0xFF5B6673),
  Color(0xFFE3E8ED),
];

/// Textura de cadenas cruzadas (X) sobre toda la superficie — el
/// tratamiento visual de una mona bloqueada. Se dibuja una sola vez
/// (sin animar) detrás/encima del contenido; nombre, descripción y
/// progreso siguen siendo legibles.
class ChainsOverlay extends StatelessWidget {
  const ChainsOverlay({super.key, this.opacity = 0.38});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ChainsPainter(color: Colors.white.withValues(alpha: opacity)),
        size: Size.infinite,
      ),
    );
  }
}

class _ChainsPainter extends CustomPainter {
  const _ChainsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    _drawChain(canvas, Offset.zero, Offset(size.width, size.height), paint);
    _drawChain(canvas, Offset(size.width, 0), Offset(0, size.height), paint);
  }

  void _drawChain(Canvas canvas, Offset from, Offset to, Paint paint) {
    const spacing = 13.0;
    final delta = to - from;
    final length = delta.distance;
    final angle = delta.direction;
    final count = (length / spacing).round();
    canvas.save();
    canvas.translate(from.dx, from.dy);
    canvas.rotate(angle);
    for (var i = 0; i <= count; i++) {
      canvas.save();
      canvas.translate(i * spacing, 0);
      canvas.rotate(i.isEven ? 0 : math.pi / 2);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 12, height: 7),
        paint,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChainsPainter oldDelegate) =>
      oldDelegate.color != color;
}

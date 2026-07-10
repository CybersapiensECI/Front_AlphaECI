import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

/// Fondo social de AlphaECI: blobs de marca difuminados + una RED DE NODOS
/// que se interconectan (metáfora de matching). Todo reacciona al puntero
/// y queda borroso y de baja opacidad, siempre por detrás del texto.
class FloatingBlobBackground extends StatefulWidget {
  const FloatingBlobBackground({super.key, required this.child});

  final Widget child;

  @override
  State<FloatingBlobBackground> createState() =>
      _FloatingBlobBackgroundState();
}

class _FloatingBlobBackgroundState extends State<FloatingBlobBackground>
    with TickerProviderStateMixin {
  // Blobs: deriva lenta de color.
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat(reverse: true);

  // Pulso al tocar.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  // Física de nodos: un ticker que integra posiciones con dt real.
  late final Ticker _ticker = createTicker(_onTick)..start();
  final _repaint = ValueNotifier<int>(0);
  Duration _last = Duration.zero;

  // Puntero en coordenadas normalizadas 0..1.
  final _pointer = ValueNotifier<Offset>(const Offset(0.5, 0.5));
  Offset _pointerTarget = const Offset(0.5, 0.5);
  Offset _prevPointer = const Offset(0.5, 0.5);

  // Nodos de la red. Posición y velocidad en espacio normalizado 0..1.
  static const _nodeCount = 18;
  final _nodes = <_Node>[];

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    for (var i = 0; i < _nodeCount; i++) {
      _nodes.add(_Node(
        pos: Offset(rnd.nextDouble(), rnd.nextDouble()),
        vel: Offset(
          (rnd.nextDouble() - 0.5) * 0.10,
          (rnd.nextDouble() - 0.5) * 0.10,
        ),
        phase: rnd.nextDouble() * math.pi * 2,
      ));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _drift.dispose();
    _pulse.dispose();
    _repaint.dispose();
    _pointer.dispose();
    super.dispose();
  }

  void _updatePointer(Offset position, Size size) {
    if (size.isEmpty) return;
    _pointerTarget = Offset(
      (position.dx / size.width).clamp(0.0, 1.0),
      (position.dy / size.height).clamp(0.0, 1.0),
    );
  }

  /// Onda al tocar/hacer clic: empuja los nodos cercanos hacia afuera.
  void _rippleAt(Offset position, Size size) {
    if (size.isEmpty) return;
    final tap = Offset(
      (position.dx / size.width).clamp(0.0, 1.0),
      (position.dy / size.height).clamp(0.0, 1.0),
    );
    for (final n in _nodes) {
      final d = n.pos - tap;
      final dist = d.distance;
      if (dist < 0.32) {
        final dir = dist > 1e-4 ? d / dist : const Offset(0, -1);
        n.vel += dir * 0.14 * (1 - dist / 0.32);
      }
    }
  }

  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    if (dt == 0) return;
    final t = elapsed.inMicroseconds / 1e6;

    // Suavizado del puntero (independiente de fps).
    final ptr = Offset.lerp(_pointer.value, _pointerTarget, (dt * 8).clamp(0.0, 1.0))!;
    _pointer.value = ptr;

    // Velocidad del puntero (estela): arrastra los nodos al mover el mouse
    // o deslizar el dedo. Acotada para evitar saltos en gestos rápidos.
    var ptrVel = (ptr - _prevPointer) / dt;
    _prevPointer = ptr;
    final pvMag = ptrVel.distance;
    if (pvMag > 2.0) ptrVel = ptrVel / pvMag * 2.0;

    for (final n in _nodes) {
      final d = ptr - n.pos;
      final dist = d.distance;
      // Atracción hacia el puntero: los nodos se "conectan" al cursor.
      if (dist > 1e-4 && dist < 0.28) {
        final pull = 0.11 * (1 - dist / 0.28);
        n.vel += d / dist * pull * dt;
      }
      // Estela: nodos cercanos son arrastrados en la dirección del gesto.
      if (dist < 0.24) {
        n.vel += ptrVel * 4.0 * dt * (1 - dist / 0.24);
      }
      // Paseo pasivo: rumbo sinusoidal propio de cada nodo — el fondo
      // siempre está vivo aunque nadie lo toque.
      final wander =
          n.phase + t * 0.30 + math.sin(t * 0.45 + n.phase * 3) * 1.3;
      n.vel +=
          Offset(math.cos(wander), math.sin(wander)) * 0.055 * dt;
      // Integrar + fricción muy leve (deriva casi perpetua).
      var pos = n.pos + n.vel * dt;
      n.vel *= (1 - 0.06 * dt);
      // Velocidad acotada: ni disparados ni detenidos.
      final speed = n.vel.distance;
      const maxSpeed = 0.16;
      const minSpeed = 0.035;
      if (speed > maxSpeed) {
        n.vel = n.vel / speed * maxSpeed;
      } else if (speed > 1e-4 && speed < minSpeed) {
        n.vel = n.vel / speed * minSpeed;
      }
      // Rebote en bordes.
      var vx = n.vel.dx, vy = n.vel.dy;
      var x = pos.dx, y = pos.dy;
      if (x < 0) {
        x = 0;
        vx = vx.abs();
      } else if (x > 1) {
        x = 1;
        vx = -vx.abs();
      }
      if (y < 0) {
        y = 0;
        vy = vy.abs();
      } else if (y > 1) {
        y = 1;
        vy = -vy.abs();
      }
      n.pos = Offset(x, y);
      n.vel = Offset(vx, vy);
    }
    if (mounted) _repaint.value++;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Blobs algo más presentes: dan color al frost de las superficies glass.
    final alpha = isDark ? 0.28 : 0.20;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerHover: (e) => _updatePointer(e.localPosition, size),
          onPointerMove: (e) => _updatePointer(e.localPosition, size),
          onPointerDown: (e) {
            _updatePointer(e.localPosition, size);
            _rippleAt(e.localPosition, size);
            _pulse.forward(from: 0);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
              // Capa 1: blobs de color que siguen al puntero.
              AnimatedBuilder(
                animation: Listenable.merge([_drift, _pulse, _pointer]),
                builder: (context, _) {
                  final t = _drift.value;
                  final ptr = _pointer.value;
                  final align = Alignment(ptr.dx * 2 - 1, ptr.dy * 2 - 1);
                  final p = _pulse.isAnimating
                      ? Curves.easeOut.transform(_pulse.value)
                      : 0.0;
                  final pulseScale = 1 + 0.10 * (1 - p) * (p > 0 ? 1 : 0);

                  Alignment follow(Alignment base, double strength) =>
                      Alignment(
                        base.x + (align.x - base.x) * strength,
                        base.y + (align.y - base.y) * strength,
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
              // Capa 2: red de personas conectándose. Sin ImageFiltered:
              // blur por frame congelaba la animación en web/HTML renderer.
              // La suavidad viene de alphas bajos (no compite con el texto).
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      isComplex: false,
                      willChange: true,
                      painter: _NetworkPainter(
                        nodes: _nodes,
                        pointer: _pointer,
                        nodeColor: scheme.primary,
                        linkColor: scheme.primary,
                        accentColor: scheme.tertiary,
                        isDark: isDark,
                        repaint: _repaint,
                      ),
                    ),
                  ),
                ),
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

/// Nodo mutable de la red.
class _Node {
  _Node({required this.pos, required this.vel, required this.phase});
  Offset pos;
  Offset vel;

  /// Fase propia del paseo: cada nodo deriva en su propio rumbo.
  final double phase;
}

/// Dibuja nodos + líneas de conexión por cercanía y enlaces al puntero.
class _NetworkPainter extends CustomPainter {
  _NetworkPainter({
    required this.nodes,
    required this.pointer,
    required this.nodeColor,
    required this.linkColor,
    required this.accentColor,
    required this.isDark,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final List<_Node> nodes;
  final ValueListenable<Offset> pointer;
  final Color nodeColor;
  final Color linkColor;
  final Color accentColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final linkDist = size.shortestSide * 0.28;
    // Alphas bajos = efecto suave sin blur (el blur por frame mataba fps).
    final nodeAlpha = isDark ? 0.45 : 0.34;
    final lineAlpha = isDark ? 0.22 : 0.17;
    final accentAlpha = isDark ? 0.34 : 0.27;

    Offset px(Offset n) => Offset(n.dx * size.width, n.dy * size.height);

    final linePaint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Enlaces entre nodos cercanos.
    for (var i = 0; i < nodes.length; i++) {
      final a = px(nodes[i].pos);
      for (var j = i + 1; j < nodes.length; j++) {
        final b = px(nodes[j].pos);
        final dist = (a - b).distance;
        if (dist < linkDist) {
          final f = 1 - dist / linkDist;
          canvas.drawLine(
            a,
            b,
            linePaint..color = linkColor.withValues(alpha: lineAlpha * f),
          );
        }
      }
    }

    // Enlaces del puntero a nodos cercanos (acento de "conexión").
    final ptrPx = px(pointer.value);
    final ptrLink = linkDist * 1.25;
    for (final n in nodes) {
      final a = px(n.pos);
      final dist = (a - ptrPx).distance;
      if (dist < ptrLink) {
        final f = 1 - dist / ptrLink;
        canvas.drawLine(
          a,
          ptrPx,
          linePaint
            ..strokeWidth = 1.4
            ..color = accentColor.withValues(alpha: accentAlpha * f),
        );
      }
    }
    linePaint.strokeWidth = 1.0;

    // Nodos = íconos de usuario (metáfora social, no astronómica).
    // Un solo layout del glifo, pintado en cada posición (barato).
    _paintIcon(
      canvas,
      Icons.person,
      nodes.map((n) => px(n.pos)),
      18,
      nodeColor.withValues(alpha: nodeAlpha),
    );

    // Puntero = ícono de usuario destacado en color de acento.
    _paintIcon(
      canvas,
      Icons.person,
      [ptrPx],
      26,
      accentColor.withValues(alpha: accentAlpha + 0.1),
    );
  }

  /// Pinta un ícono de Material (como glifo vectorial) en varias posiciones.
  void _paintIcon(
    Canvas canvas,
    IconData icon,
    Iterable<Offset> centers,
    double sizePx,
    Color color,
  ) {
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: sizePx,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
    )..layout();
    final half = Offset(tp.width / 2, tp.height / 2);
    for (final c in centers) {
      tp.paint(canvas, c - half);
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkPainter oldDelegate) => false;
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

/// Scaffold con fondo social (blobs + red de nodos). Reemplazo directo de
/// Scaffold para pantallas que quieran el fondo premium.
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

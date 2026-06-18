import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stronger/theme/app_colors.dart';

/// Detalle decorativo "neural": puntos cyan conectados por líneas finas de baja
/// opacidad. Pensado para headers y estados vacíos. Es estático (con semilla
/// fija) para no costar rendimiento; admite un [child] dibujado por encima.
class NeuralBackground extends StatelessWidget {
  final Widget? child;
  final int nodeCount;
  final double maxLinkDistance;

  /// Color base de puntos y líneas. Por defecto, el acento del tema activo.
  final Color? color;

  /// Semilla para la distribución (fija el patrón entre rebuilds).
  final int seed;

  const NeuralBackground({
    super.key,
    this.child,
    this.nodeCount = 22,
    this.maxLinkDistance = 120,
    this.color,
    this.seed = 7,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppColors.of(context).accent;
    return CustomPaint(
      painter: _NeuralPainter(
        color: base,
        nodeCount: nodeCount,
        maxLinkDistance: maxLinkDistance,
        seed: seed,
      ),
      child: child,
    );
  }
}

class _NeuralPainter extends CustomPainter {
  final Color color;
  final int nodeCount;
  final double maxLinkDistance;
  final int seed;

  _NeuralPainter({
    required this.color,
    required this.nodeCount,
    required this.maxLinkDistance,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rng = Random(seed);
    final nodes = List<Offset>.generate(
      nodeCount,
      (_) => Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
    );

    final linePaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Líneas entre nodos cercanos (más opacas cuanto más cerca).
    for (var i = 0; i < nodes.length; i++) {
      for (var j = i + 1; j < nodes.length; j++) {
        final d = (nodes[i] - nodes[j]).distance;
        if (d <= maxLinkDistance) {
          final strength = 1 - (d / maxLinkDistance);
          linePaint.color = color.withValues(alpha: 0.10 * strength);
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }

    // Nodos: punto + halo tenue.
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (final n in nodes) {
      dotPaint.color = color.withValues(alpha: 0.10);
      canvas.drawCircle(n, 5, dotPaint);
      dotPaint.color = color.withValues(alpha: 0.45);
      canvas.drawCircle(n, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_NeuralPainter old) =>
      old.color != color ||
      old.nodeCount != nodeCount ||
      old.maxLinkDistance != maxLinkDistance ||
      old.seed != seed;
}

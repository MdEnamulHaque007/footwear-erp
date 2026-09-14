import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Two concentric arcs — Side A outside, Side B inside.
///
/// Each arc sweeps clockwise from the top (angle `-π/2`) to its fraction of a
/// full turn, drawn point-by-point along `x = cx + r·cos θ`, `y = cy + r·sin θ`
/// so the sweep itself is the animation.
class RadialProgressChart extends StatefulWidget {
  const RadialProgressChart({
    super.key,
    required this.ratioA,
    required this.ratioB,
    this.colorA = const Color(0xFFF57C00),
    this.colorB = const Color(0xFFC2185B),
    this.size = 170,
  });

  /// Fraction of the larger side, 0–1.
  final double ratioA;
  final double ratioB;
  final Color colorA;
  final Color colorB;
  final double size;

  @override
  State<RadialProgressChart> createState() => _RadialProgressChartState();
}

class _RadialProgressChartState extends State<RadialProgressChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _sweep;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _sweep = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant RadialProgressChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-run the sweep whenever the data changes so the arc grows into place.
    if (oldWidget.ratioA != widget.ratioA ||
        oldWidget.ratioB != widget.ratioB) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.size,
    height: widget.size,
    child: AnimatedBuilder(
      animation: _sweep,
      builder: (context, _) => CustomPaint(
        painter: _RadialPainter(
          progress: _sweep.value,
          ratioA: widget.ratioA.clamp(0.0, 1.0),
          ratioB: widget.ratioB.clamp(0.0, 1.0),
          colorA: widget.colorA,
          colorB: widget.colorB,
        ),
      ),
    ),
  );
}

class _RadialPainter extends CustomPainter {
  _RadialPainter({
    required this.progress,
    required this.ratioA,
    required this.ratioB,
    required this.colorA,
    required this.colorB,
  });

  final double progress;
  final double ratioA;
  final double ratioB;
  final Color colorA;
  final Color colorB;

  /// Half of a full turn, so a full arc starts at the top and sweeps clockwise.
  static const double _start = -math.pi / 2;
  static const double _fullTurn = 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 - 6;
    final innerRadius = outerRadius - 18;
    const stroke = 12.0;

    _arc(canvas, center, outerRadius, stroke, ratioA, colorA);
    _arc(canvas, center, innerRadius, stroke, ratioB, colorB);
  }

  void _arc(
    Canvas canvas,
    Offset center,
    double radius,
    double stroke,
    double ratio,
    Color color,
  ) {
    // Track: the full ring, faint.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (ratio <= 0) return;

    // Sweep from the top by ratio × 360°, walked in small angular steps so the
    // arc is a polyline along the circle: (cx + r·cos θ, cy + r·sin θ).
    final endAngle = _start + _fullTurn * ratio * progress;
    const steps = 90;
    final stepAngle = (endAngle - _start) / steps;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final theta = _start + stepAngle * i;
      final point = Offset(
        center.dx + radius * math.cos(theta),
        center.dy + radius * math.sin(theta),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialPainter old) =>
      old.progress != progress ||
      old.ratioA != ratioA ||
      old.ratioB != ratioB;
}

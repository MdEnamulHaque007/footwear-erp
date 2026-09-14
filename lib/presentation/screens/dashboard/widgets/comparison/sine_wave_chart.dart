import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Two travelling sine waves, one per comparison side.
///
/// Each wave is drawn from `y(t) = A · sin(ωt + φ) + k`, where the amplitude `A`
/// scales with that side's share of the larger total, `φ` advances with the
/// animation so the crests travel, and the two sides are given opposite phase
/// directions so they visibly cross rather than move in lockstep.
///
/// The labels and values are supplied per side, so this chart compares any two
/// departments rather than a fixed Cutting-vs-Sewing pair.
class SineWaveChart extends StatefulWidget {
  const SineWaveChart({
    super.key,
    required this.valueA,
    required this.valueB,
    this.labelA = 'Side A',
    this.labelB = 'Side B',
    this.colorA = const Color(0xFFF57C00),
    this.colorB = const Color(0xFFC2185B),
    this.height = 150,
    this.paused = false,
  });

  final double valueA;
  final double valueB;
  final String labelA;
  final String labelB;
  final Color colorA;
  final Color colorB;
  final double height;

  /// Freezes the phase advance while keeping the current frame on screen.
  final bool paused;

  @override
  State<SineWaveChart> createState() => _SineWaveChartState();
}

class _SineWaveChartState extends State<SineWaveChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (!widget.paused) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant SineWaveChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.paused && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    width: double.infinity,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _SineWavePainter(
          phase: _controller.value * 2 * math.pi,
          valueA: widget.valueA,
          valueB: widget.valueB,
          colorA: widget.colorA,
          colorB: widget.colorB,
        ),
      ),
    ),
  );
}

class _SineWavePainter extends CustomPainter {
  _SineWavePainter({
    required this.phase,
    required this.valueA,
    required this.valueB,
    required this.colorA,
    required this.colorB,
  });

  final double phase;
  final double valueA;
  final double valueB;
  final Color colorA;
  final Color colorB;

  /// Number of full crests across the width.
  static const double _waves = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    // Scale each amplitude by its share of the larger total, leaving headroom
    // so the taller wave never clips the top edge.
    final maxValue = math.max(valueA, valueB);

    _drawAxis(canvas, size, midY);
    _drawWave(
      canvas,
      size,
      midY,
      amplitude: maxValue <= 0 ? 0 : (valueA / maxValue) * midY * 0.72,
      phaseOffset: phase,
      color: colorA,
    );
    _drawWave(
      canvas,
      size,
      midY,
      amplitude: maxValue <= 0 ? 0 : (valueB / maxValue) * midY * 0.72,
      // Opposite direction so the two crests cross instead of tracking.
      phaseOffset: -phase,
      color: colorB,
    );
  }

  void _drawAxis(Canvas canvas, Size size, double midY) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double midY, {
    required double amplitude,
    required double phaseOffset,
    required Color color,
  }) {
    final path = Path();
    final step = math.max(1.0, size.width / 120);
    for (double x = 0; x <= size.width; x += step) {
      // t normalised to 0..1 across the width, then scaled to `_waves` crests.
      final t = x / size.width;
      final y =
          amplitude * math.sin(2 * math.pi * _waves * t + phaseOffset) + midY;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Soft fill under the curve, then the stroke on top.
    final fill = Path.from(path)
      ..lineTo(size.width, midY)
      ..lineTo(0, midY)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SineWavePainter old) =>
      old.phase != phase ||
      old.valueA != valueA ||
      old.valueB != valueB;
}

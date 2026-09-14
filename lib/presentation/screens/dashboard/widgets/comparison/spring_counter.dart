import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Counts up from zero to [value] with an elastic settle.
///
/// The overshoot from [Curves.elasticOut] gives the number a spring feel so a
/// changing comparison total reads as motion rather than a silent swap.
class SpringCounter extends StatelessWidget {
  const SpringCounter({
    super.key,
    required this.value,
    required this.color,
    this.fontSize = 26,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 1400),
  });

  final double value;
  final Color color;
  final double fontSize;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    // Changing `value` retriggers the tween from the current displayed number.
    tween: Tween<double>(begin: 0, end: value),
    duration: duration,
    curve: Curves.elasticOut,
    builder: (context, animated, _) => Text(
      '${NumberFormat.decimalPattern().format(animated.round())}$suffix',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

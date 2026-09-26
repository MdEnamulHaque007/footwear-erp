/// ============================================================================
/// ফাইল: lib/presentation/screens/dashboard/widgets/comparison/spring_counter.dart
/// স্তর: Presentation Screen | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: SpringCounter
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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

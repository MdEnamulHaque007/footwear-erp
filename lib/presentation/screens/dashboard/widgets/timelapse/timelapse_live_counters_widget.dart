/// ============================================================================
/// ফাইল: lib/presentation/screens/dashboard/widgets/timelapse/timelapse_live_counters_widget.dart
/// স্তর: Presentation Screen | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: TimelapseLiveCountersWidget, _CounterCard
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/color_palette.dart';
import '../../../../../domain/entities/timelapse/timelapse_data_entity.dart';

class TimelapseLiveCountersWidget extends StatelessWidget {
  const TimelapseLiveCountersWidget({
    super.key,
    required this.data,
    required this.visiblePoints,
  });

  final TimelapseData data;
  final int visiblePoints;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 4
          : constraints.maxWidth >= 600
          ? 3
          : 2;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final series in data.series)
            SizedBox(
              width: width,
              child: _CounterCard(
                label: series.department.label,
                color: _color(series.department.label),
                value: series.valueAt(visiblePoints - 1),
              ),
            ),
        ],
      );
    },
  );

  static Color _color(String label) => switch (label) {
    'Master LC' => ColorPalette.masterLc,
    'Purchase Order' => ColorPalette.purchaseOrder,
    'Cutting' => ColorPalette.cutting,
    'Sewing' => ColorPalette.sewing,
    'Production' => ColorPalette.production,
    'Issue' => ColorPalette.issue,
    'Export' => ColorPalette.export,
    _ => ColorPalette.primary,
  };
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.label,
    required this.color,
    required this.value,
  });

  final String label;
  final Color color;
  final double value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(end: value),
            duration: const Duration(milliseconds: 220),
            builder: (context, animated, _) => Text(
              NumberFormat.decimalPattern().format(animated),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

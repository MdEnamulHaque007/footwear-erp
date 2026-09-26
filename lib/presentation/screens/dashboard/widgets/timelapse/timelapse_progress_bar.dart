/// ============================================================================
/// ফাইল: lib/presentation/screens/dashboard/widgets/timelapse/timelapse_progress_bar.dart
/// স্তর: Presentation Screen | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: TimelapseProgressBar
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';

class TimelapseProgressBar extends StatelessWidget {
  const TimelapseProgressBar({
    super.key,
    required this.progress,
    required this.visiblePoints,
    required this.totalPoints,
    required this.elapsedSeconds,
    required this.durationSeconds,
  });

  final double progress;
  final int visiblePoints;
  final int totalPoints;
  final int elapsedSeconds;
  final int durationSeconds;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Day $visiblePoints / $totalPoints'),
              Text('${(progress * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Elapsed: ${elapsedSeconds}s / ${durationSeconds}s',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

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

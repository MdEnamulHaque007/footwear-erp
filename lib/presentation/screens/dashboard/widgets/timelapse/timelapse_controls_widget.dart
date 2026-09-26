/// ============================================================================
/// ফাইল: lib/presentation/screens/dashboard/widgets/timelapse/timelapse_controls_widget.dart
/// স্তর: Presentation Screen | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: TimelapseControlsWidget
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';

import '../../../../blocs/timelapse/timelapse_state.dart';

class TimelapseControlsWidget extends StatelessWidget {
  const TimelapseControlsWidget({
    super.key,
    required this.state,
    required this.onPlay,
    required this.onPause,
    required this.onReset,
    required this.onSpeedChanged,
  });

  final TimelapseLoaded state;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final ValueChanged<double> onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    final complete = state.visiblePoints >= state.data.totalPoints;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: complete
                  ? null
                  : state.isPlaying
                  ? onPause
                  : onPlay,
              icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
              label: Text(state.isPlaying ? 'Pause' : 'Play'),
            ),
            IconButton(
              tooltip: 'Reset',
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt),
            ),
            DropdownButton<double>(
              value: state.playbackSpeed,
              onChanged: (value) {
                if (value != null) onSpeedChanged(value);
              },
              items: const [
                DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                DropdownMenuItem(value: 1.0, child: Text('1x')),
                DropdownMenuItem(value: 2.0, child: Text('2x')),
              ],
            ),
            Text(
              'Elapsed: ${state.elapsedSeconds}s / ${state.durationSeconds}s',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

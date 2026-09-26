/// ============================================================================
/// ফাইল: lib/presentation/screens/dashboard/timelapse_dashboard_screen.dart
/// স্তর: Presentation Screen | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: TimelapseDashboardScreen, _TimelapseDashboardScreenState
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/timelapse/timelapse_config_entity.dart';
import '../../blocs/timelapse/timelapse_bloc.dart';
import '../../blocs/timelapse/timelapse_event.dart';
import '../../blocs/timelapse/timelapse_state.dart';
import '../../routes/route_constants.dart';
import '../../widgets/app_drawer.dart';
import 'widgets/timelapse/department_multi_select.dart';
import 'widgets/timelapse/timelapse_chart_widget.dart';
import 'widgets/timelapse/timelapse_controls_widget.dart';
import 'widgets/timelapse/timelapse_live_counters_widget.dart';
import 'widgets/timelapse/timelapse_progress_bar.dart';

class TimelapseDashboardScreen extends StatefulWidget {
  const TimelapseDashboardScreen({super.key});

  @override
  State<TimelapseDashboardScreen> createState() =>
      _TimelapseDashboardScreenState();
}

class _TimelapseDashboardScreenState extends State<TimelapseDashboardScreen> {
  late TimelapseConfig _config;

  @override
  void initState() {
    super.initState();
    _config = TimelapseConfig.defaults();
  }

  Future<void> _pickDate({required bool from}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: from ? _config.fromDate : _config.toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _config = from
          ? _config.copyWith(fromDate: picked)
          : _config.copyWith(toDate: picked);
    });
  }

  void _load() => context.read<TimelapseBloc>().add(LoadTimelapseData(_config));

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: const AppDrawer(),
    appBar: AppBar(
      leadingWidth: 96,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => context.go(RouteConstants.dashboard),
            icon: const Icon(Icons.arrow_back),
          ),
          Builder(
            builder: (drawerContext) => IconButton(
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(drawerContext).openDrawer(),
              icon: const Icon(Icons.menu),
            ),
          ),
        ],
      ),
      title: const Text('Time-Lapse Report'),
      actions: [
        IconButton(
          tooltip: 'Close',
          onPressed: () => context.go(RouteConstants.dashboard),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
    body: BlocConsumer<TimelapseBloc, TimelapseState>(
      listener: (context, state) {
        if (state is TimelapseError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) => LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: EdgeInsets.all(constraints.maxWidth >= 760 ? 28 : 16),
          children: [
            _filterPanel(context),
            const SizedBox(height: 16),
            if (state is TimelapseLoading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state is TimelapseLoaded) ...[
              TimelapseControlsWidget(
                state: state,
                onPlay: () =>
                    context.read<TimelapseBloc>().add(const PlayTimelapse()),
                onPause: () =>
                    context.read<TimelapseBloc>().add(const PauseTimelapse()),
                onReset: () =>
                    context.read<TimelapseBloc>().add(const ResetTimelapse()),
                onSpeedChanged: (speed) =>
                    context.read<TimelapseBloc>().add(SetPlaybackSpeed(speed)),
              ),
              const SizedBox(height: 16),
              TimelapseChartWidget(
                data: state.data,
                visiblePoints: state.visiblePoints,
              ),
              const SizedBox(height: 16),
              TimelapseLiveCountersWidget(
                data: state.data,
                visiblePoints: state.visiblePoints,
              ),
              const SizedBox(height: 16),
              TimelapseProgressBar(
                progress: state.progress,
                visiblePoints: state.visiblePoints,
                totalPoints: state.data.totalPoints,
                elapsedSeconds: state.elapsedSeconds,
                durationSeconds: state.durationSeconds,
              ),
              if (state.progress >= 1) ...[
                const SizedBox(height: 16),
                _completionCard(context, state),
              ],
            ] else if (state is TimelapseInitial)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('Choose filters and load a timeline.'),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _filterPanel(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline filters',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          DepartmentMultiSelect(
            selected: _config.departments,
            onChanged: (departments) => setState(
              () => _config = _config.copyWith(departments: departments),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _dateButton(
                context,
                'From',
                _config.fromDate,
                () => _pickDate(from: true),
              ),
              _dateButton(
                context,
                'To',
                _config.toDate,
                () => _pickDate(from: false),
              ),
              DropdownButton<DataType>(
                value: _config.dataType,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _config = _config.copyWith(dataType: value));
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: DataType.quantity,
                    child: Text('Quantity'),
                  ),
                  DropdownMenuItem(value: DataType.value, child: Text('Value')),
                ],
              ),
              DropdownButton<int>(
                value: _config.durationSeconds,
                onChanged: (value) {
                  if (value != null) {
                    setState(
                      () => _config = _config.copyWith(durationSeconds: value),
                    );
                  }
                },
                items: const [
                  DropdownMenuItem(value: 30, child: Text('30 seconds')),
                  DropdownMenuItem(value: 60, child: Text('60 seconds')),
                  DropdownMenuItem(value: 120, child: Text('120 seconds')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.query_stats),
            label: const Text('Load Data'),
          ),
        ],
      ),
    ),
  );

  Widget _dateButton(
    BuildContext context,
    String label,
    DateTime date,
    VoidCallback onPressed,
  ) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.calendar_today_outlined, size: 18),
    label: Text('$label: ${DateFormat('dd MMM yyyy').format(date)}'),
  );

  Widget _completionCard(BuildContext context, TimelapseLoaded state) {
    final firstTotal = state.data.series.fold<double>(
      0,
      (total, series) => total + series.valueAt(0),
    );
    final peak = state.data.series.fold<double>(
      0,
      (total, series) => total + series.valueAt(state.data.totalPoints - 1),
    );
    final growth = firstTotal == 0
        ? 0
        : ((peak - firstTotal) / firstTotal) * 100;
    final peakDate = state.data.toDate;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time-lapse complete',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text('Growth from first day: ${growth.toStringAsFixed(1)}%'),
            const SizedBox(height: 3),
            Text('Peak day: ${DateFormat('dd MMM yyyy').format(peakDate)}'),
            const SizedBox(height: 3),
            Text(
              'Peak cumulative total: ${NumberFormat.decimalPattern().format(peak)}',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Snapshot export will be available in reports.',
                  ),
                ),
              ),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Export Snapshot'),
            ),
          ],
        ),
      ),
    );
  }
}

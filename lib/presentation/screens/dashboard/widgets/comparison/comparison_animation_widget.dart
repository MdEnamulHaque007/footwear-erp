/// ============================================================================
/// ফাইল: lib/presentation/screens/dashboard/widgets/comparison/comparison_animation_widget.dart
/// স্তর: Presentation Screen | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: ComparisonAnimationWidget, LegacyComparisonAnimationWidget, _ComparisonAnimationWidgetState
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/color_palette.dart';
import '../../../../../domain/entities/dashboard/comparison_data_entity.dart';
import '../../../../../domain/entities/dashboard/comparison_item_entity.dart';
import '../../../../../domain/entities/dashboard/department_option_entity.dart';
import '../../../../blocs/dashboard/dashboard_bloc.dart';
import '../../../../blocs/dashboard/dashboard_event.dart';
import '../../../../blocs/dashboard/dashboard_state.dart';
import 'department_selector.dart';
import 'radial_progress_chart.dart';
import 'sine_wave_chart.dart';
import 'spring_counter.dart';
import 'multi_department_comparison_widget.dart';
import 'comparison_matrix_widget.dart';

/// Public entry point for the all-department comparison experience.
class ComparisonAnimationWidget extends StatelessWidget {
  const ComparisonAnimationWidget({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      MultiDepartmentComparisonWidget(),
      SizedBox(height: 16),
      ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16),
        title: Text('Advanced X × Y Comparison'),
        subtitle: Text('Build a matrix by criteria, department and measure'),
        children: [Padding(padding: EdgeInsets.fromLTRB(8, 0, 8, 8), child: ComparisonMatrixWidget())],
      ),
    ],
  );
}

/// Side-by-side department comparison with independent date ranges.
///
/// The user picks any two of the seven production stages ([DepartmentOption.all])
/// and gives each its own range, so a stage can be measured against itself
/// across two periods or against a different stage. Pressing View dispatches
/// [LoadComparisonData]; the BLoC fetches both sides in parallel and derives the
/// insight.
class LegacyComparisonAnimationWidget extends StatefulWidget {
  const LegacyComparisonAnimationWidget({super.key});

  @override
  State<LegacyComparisonAnimationWidget> createState() =>
      _ComparisonAnimationWidgetState();
}

class _ComparisonAnimationWidgetState
    extends State<LegacyComparisonAnimationWidget> {
  // Defaults: Cutting vs Sewing over two halves of a year.
  DepartmentOption _departmentA = DepartmentOption.all[2];
  DepartmentOption _departmentB = DepartmentOption.all[3];
  late DateTimeRange _rangeA;
  late DateTimeRange _rangeB;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _rangeA = DateTimeRange(
      start: DateTime(2026, 1, 1),
      end: DateTime(2026, 6, 30),
    );
    _rangeB = DateTimeRange(
      start: DateTime(2026, 7, 1),
      end: DateTime(2026, 12, 31),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  void _load() {
    context.read<DashboardBloc>().add(
      LoadComparisonData(
        items: [
          ComparisonItem(
            id: 'legacy-a',
            department: _departmentA,
            fromDate: _rangeA.start,
            toDate: _rangeA.end,
          ),
          ComparisonItem(
            id: 'legacy-b',
            department: _departmentB,
            fromDate: _rangeB.start,
            toDate: _rangeB.end,
          ),
        ],
      ),
    );
  }

  Future<void> _pickRange({required bool sideA}) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: sideA ? _rangeA : _rangeB,
      helpText: sideA ? 'Select Side A range' : 'Select Side B range',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (sideA) {
        _rangeA = picked;
      } else {
        _rangeB = picked;
      }
    });
  }

  void _reset() {
    setState(() {
      _departmentA = DepartmentOption.all[2];
      _departmentB = DepartmentOption.all[3];
      _rangeA = DateTimeRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 6, 30),
      );
      _rangeB = DateTimeRange(
        start: DateTime(2026, 7, 1),
        end: DateTime(2026, 12, 31),
      );
      _paused = false;
    });
    _load();
  }

  static String _format(DateTime date) =>
      DateFormat('dd MMM yyyy').format(date);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Department Comparison',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Compare any two departments over independent ranges.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _sideCards(theme),
            const SizedBox(height: 14),
            _controls(theme),
            const SizedBox(height: 18),
            BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                final loaded = state is DashboardLoaded ? state : null;
                if (loaded == null) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final a = loaded.comparisonA;
                final b = loaded.comparisonB;
                if (a == null || b == null) {
                  return SizedBox(
                    height: 180,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Comparison unavailable for this range.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return _results(theme, a, b, loaded.comparisonInsight);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// The two department + range pickers, side by side when there is room.
  Widget _sideCards(ThemeData theme) => LayoutBuilder(
    builder: (context, constraints) {
      final cardA = _sideCard(theme, sideA: true);
      final cardB = _sideCard(theme, sideA: false);
      if (constraints.maxWidth < 640) {
        return Column(
          children: [cardA, const SizedBox(height: 14), cardB],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cardA),
          const SizedBox(width: 14),
          Expanded(child: cardB),
        ],
      );
    },
  );

  Widget _sideCard(ThemeData theme, {required bool sideA}) {
    final range = sideA ? _rangeA : _rangeB;
    final option = sideA ? _departmentA : _departmentB;
    final accent = sideA ? ColorPalette.cutting : ColorPalette.sewing;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
        color: accent.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DepartmentSelector(
            title: sideA ? 'Side A' : 'Side B',
            selectedLabel: option.label,
            accent: accent,
            onChanged: (label) => setState(() {
              if (sideA) {
                _departmentA = DepartmentOption.fromLabel(label);
              } else {
                _departmentB = DepartmentOption.fromLabel(label);
              }
            }),
          ),
          const SizedBox(height: 10),
          _dateField(
            label: 'From',
            value: _format(range.start),
            onTap: () => _pickRange(sideA: sideA),
          ),
          const SizedBox(height: 8),
          _dateField(
            label: 'To',
            value: _format(range.end),
            onTap: () => _pickRange(sideA: sideA),
          ),
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) => InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        suffixIcon: const Icon(Icons.date_range, size: 18),
      ),
      child: Text(value),
    ),
  );

  Widget _controls(ThemeData theme) => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      FilledButton.icon(
        onPressed: _load,
        icon: const Icon(Icons.play_arrow, size: 18),
        label: const Text('View'),
      ),
      OutlinedButton.icon(
        onPressed: () => setState(() => _paused = !_paused),
        icon: Icon(_paused ? Icons.play_arrow : Icons.pause, size: 18),
        label: Text(_paused ? 'Resume' : 'Pause'),
      ),
      OutlinedButton.icon(
        onPressed: _reset,
        icon: const Icon(Icons.restart_alt, size: 18),
        label: const Text('Reset'),
      ),
    ],
  );

  // --------------------------------------------------------------- results

  Widget _results(
    ThemeData theme,
    ComparisonRangeEntity a,
    ComparisonRangeEntity b,
    ComparisonInsightEntity? insight,
  ) {
    final hasData = a.totalQuantity > 0 || b.totalQuantity > 0;
    final ratioA = insight?.ratioA ?? 0;
    final ratioB = insight?.ratioB ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasData)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                'No records for either department in these ranges.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 660;
              final wave = _wavePanel(a, b);
              final radial = _radialPanel(theme, ratioA, ratioB);
              if (compact) {
                return Column(
                  children: [wave, const SizedBox(height: 14), radial],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: wave),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: radial),
                ],
              );
            },
          ),
        if (hasData) ...[
          const SizedBox(height: 16),
          _sideTotals(a, b),
          if (insight != null) ...[
            const SizedBox(height: 14),
            _insightCard(theme, insight),
          ],
        ],
      ],
    );
  }

  Widget _wavePanel(ComparisonRangeEntity a, ComparisonRangeEntity b) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SineWaveChart(
        valueA: a.totalQuantity.toDouble(),
        valueB: b.totalQuantity.toDouble(),
        labelA: a.department,
        labelB: b.department,
        colorA: ColorPalette.cutting,
        colorB: ColorPalette.sewing,
        paused: _paused,
      ),
      const SizedBox(height: 10),
      Text(
        '${_format(a.fromDate)} – ${_format(a.toDate)}   vs   '
        '${_format(b.fromDate)} – ${_format(b.toDate)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );

  Widget _radialPanel(ThemeData theme, double ratioA, double ratioB) => Column(
    children: [
      RadialProgressChart(
        ratioA: ratioA,
        ratioB: ratioB,
        colorA: ColorPalette.cutting,
        colorB: ColorPalette.sewing,
        size: 160,
      ),
      const SizedBox(height: 8),
      Text(
        'Larger side = full sweep',
        style: theme.textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
    ],
  );

  /// Spring-animated totals for each side.
  Widget _sideTotals(ComparisonRangeEntity a, ComparisonRangeEntity b) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final rowA = _totalTile(a, ColorPalette.cutting);
          final rowB = _totalTile(b, ColorPalette.sewing);
          if (constraints.maxWidth < 460) {
            return Column(children: [rowA, const SizedBox(height: 8), rowB]);
          }
          return Row(
            children: [
              Expanded(child: rowA),
              const SizedBox(width: 14),
              Expanded(child: rowB),
            ],
          );
        },
      );

  Widget _totalTile(ComparisonRangeEntity side, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            side.department,
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SpringCounter(
          value: side.totalQuantity.toDouble(),
          color: color,
          fontSize: 18,
          duration: const Duration(milliseconds: 1600),
        ),
      ],
    ),
  );

  Widget _insightCard(ThemeData theme, ComparisonInsightEntity insight) {
    final color = switch (insight.trend) {
      'up' => ColorPalette.success,
      'down' => ColorPalette.error,
      _ => ColorPalette.muted,
    };
    final icon = switch (insight.trend) {
      'up' => Icons.trending_up,
      'down' => Icons.trending_down,
      _ => Icons.trending_flat,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${insight.departmentB} vs ${insight.departmentA}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${insight.growthPercent >= 0 ? '+' : ''}'
                '${insight.growthPercent.toStringAsFixed(1)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          if (insight.summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(insight.summary, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

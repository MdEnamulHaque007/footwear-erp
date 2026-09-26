/// ============================================================================
/// ফাইল: lib/presentation/screens/dashboard/widgets/comparison/comparison_matrix_widget.dart
/// স্তর: Presentation Screen | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: ComparisonMatrixWidget, _ComparisonMatrixWidgetState
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/color_palette.dart';
import '../../../../../domain/entities/dashboard/comparison_matrix_entity.dart';
import '../../../../../domain/entities/dashboard/criteria_option_entity.dart';
import '../../../../../domain/entities/dashboard/department_option_entity.dart';
import '../../../../blocs/dashboard/dashboard_bloc.dart';
import '../../../../blocs/dashboard/dashboard_event.dart';
import '../../../../blocs/dashboard/dashboard_state.dart';
import 'criteria_selector.dart';

class ComparisonMatrixWidget extends StatefulWidget {
  const ComparisonMatrixWidget({super.key});

  @override
  State<ComparisonMatrixWidget> createState() => _ComparisonMatrixWidgetState();
}

class _ComparisonMatrixWidgetState extends State<ComparisonMatrixWidget> {
  late Set<DepartmentOption> _departments;
  CriteriaOption _xCriteria = CriteriaOption.all.first;
  CriteriaOption _yCriteria = CriteriaOption.all[1];
  ValueType _valueType = ValueType.quantity;
  late DateTimeRange _range;

  static const _seriesColors = [
    ColorPalette.primary,
    ColorPalette.secondary,
    ColorPalette.success,
    ColorPalette.sewing,
    ColorPalette.production,
    ColorPalette.issue,
    ColorPalette.export,
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
    _departments = {DepartmentOption.all[2], DepartmentOption.all[3]};
  }

  void _compare() {
    if (_departments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one department.')),
      );
      return;
    }
    final selected = _departments.toList()
      ..sort((a, b) => DepartmentOption.all.indexOf(a).compareTo(DepartmentOption.all.indexOf(b)));
    context.read<DashboardBloc>().add(
      LoadComparisonMatrix(
        collections: selected.map((option) => option.collection).toList(),
        dateFields: selected.map((option) => option.dateField).toList(),
        xCriteria: _xCriteria,
        yCriteria: _yCriteria,
        valueType: _valueType,
        fromDate: _range.start,
        toDate: _range.end,
      ),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _range,
    );
    if (range != null && mounted) {
      setState(() => _range = range);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🎯 Advanced Comparison', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Choose X-axis, Y-axis and a quantity or value measure.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Text('Departments', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in DepartmentOption.all)
                FilterChip(
                  label: Text('${option.emoji} ${option.label}'),
                  selected: _departments.contains(option),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _departments.add(option);
                    } else {
                      _departments.remove(option);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 640;
              final selectors = [
                Expanded(
                  child: CriteriaSelector(
                    label: 'X-Axis',
                    selected: _xCriteria,
                    onChanged: (value) => setState(() => _xCriteria = value),
                  ),
                ),
                const SizedBox(width: 12, height: 12),
                Expanded(
                  child: CriteriaSelector(
                    label: 'Y-Axis',
                    selected: _yCriteria,
                    onChanged: (value) => setState(() => _yCriteria = value),
                  ),
                ),
              ];
              return wide
                  ? Row(children: selectors)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [selectors[0], const SizedBox(height: 12), selectors[2]],
                    );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final valuePicker = DropdownButtonFormField<ValueType>(
                key: ValueKey(_valueType),
                initialValue: _valueType,
                decoration: const InputDecoration(labelText: 'Z-Value', border: OutlineInputBorder()),
                items: ValueType.values
                    .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _valueType = value);
                  }
                },
              );
              final dateButton = OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range_outlined),
                label: Text('${DateFormat('dd MMM yy').format(_range.start)} – ${DateFormat('dd MMM yy').format(_range.end)}'),
              );
              return constraints.maxWidth >= 500
                  ? Row(children: [Expanded(child: valuePicker), const SizedBox(width: 12), dateButton])
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [valuePicker, const SizedBox(height: 12), dateButton]);
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _compare, icon: const Icon(Icons.analytics_outlined), label: const Text('Compare')),
          const SizedBox(height: 18),
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is! DashboardLoaded) {
                return const SizedBox.shrink();
              }
              if (state.isComparisonMatrixLoading) {
                return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
              }
              if (state.comparisonMatrixError.isNotEmpty) {
                return _message(state.comparisonMatrixError, error: true);
              }
              final matrix = state.comparisonMatrix;
              if (matrix == null) {
                return _message('Ready. Select criteria and press Compare.');
              }
              if (matrix.isEmpty) {
                return _message('No data for this selection.');
              }
              return _buildMatrix(matrix);
            },
          ),
        ],
      ),
    ),
  );

  Widget _message(String message, {bool error = false}) => SizedBox(
    height: 100,
    child: Center(child: Text(message, style: TextStyle(color: error ? ColorPalette.error : ColorPalette.muted))),
  );

  Widget _buildMatrix(ComparisonMatrix matrix) {
    final bothCategories = matrix.xCriteria.type != CriteriaType.date && matrix.yCriteria.type != CriteriaType.date;
    final chart = bothCategories
        ? _heatmap(matrix)
        : matrix.xCriteria.type == CriteriaType.date
        ? _lineChart(matrix)
        : _barChart(matrix);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 280, child: chart),
        const SizedBox(height: 12),
        _legend(matrix),
        const SizedBox(height: 12),
        _table(matrix),
      ],
    );
  }

  Widget _lineChart(ComparisonMatrix matrix) => LineChart(
    LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: _titles(matrix.xLabels),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        for (var y = 0; y < matrix.yLabels.length; y++)
          LineChartBarData(
            isCurved: true,
            color: _seriesColors[y % _seriesColors.length],
            barWidth: 3,
            dotData: const FlDotData(show: false),
            spots: [for (var x = 0; x < matrix.xLabels.length; x++) FlSpot(x.toDouble(), matrix.valueAt(x, y))],
          ),
      ],
    ),
  );

  Widget _barChart(ComparisonMatrix matrix) => BarChart(
    BarChartData(
      alignment: BarChartAlignment.spaceAround,
      titlesData: _titles(matrix.xLabels),
      borderData: FlBorderData(show: false),
      barGroups: [
        for (var x = 0; x < matrix.xLabels.length; x++)
          BarChartGroupData(
            x: x,
            barsSpace: 3,
            barRods: [
              for (var y = 0; y < matrix.yLabels.length; y++)
                BarChartRodData(toY: matrix.valueAt(x, y), color: _seriesColors[y % _seriesColors.length], width: 10),
            ],
          ),
      ],
    ),
  );

  FlTitlesData _titles(List<String> labels) => FlTitlesData(
    topTitles: const AxisTitles(),
    rightTitles: const AxisTitles(),
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 38,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          if (index < 0 || index >= labels.length) {
            return const SizedBox.shrink();
          }
          return SideTitleWidget(
            axisSide: meta.axisSide,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                labels[index],
                style: const TextStyle(fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _heatmap(ComparisonMatrix matrix) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: _table(matrix, heatmap: true),
  );

  Widget _legend(ComparisonMatrix matrix) => Wrap(
    spacing: 12,
    runSpacing: 6,
    children: [
      for (var index = 0; index < matrix.yLabels.length; index++)
        Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 10, height: 10, color: _seriesColors[index % _seriesColors.length]), const SizedBox(width: 4), Text(matrix.yLabels[index], style: const TextStyle(fontSize: 12))]),
    ],
  );

  Widget _table(ComparisonMatrix matrix, {bool heatmap = false}) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      headingRowColor: WidgetStatePropertyAll(ColorPalette.surfaceMuted),
      columns: [DataColumn(label: Text(matrix.yCriteria.label)), for (final label in matrix.xLabels) DataColumn(label: Text(label))],
      rows: [
        for (var y = 0; y < matrix.yLabels.length; y++)
          DataRow(
            cells: [
              DataCell(Text(matrix.yLabels[y])),
              for (var x = 0; x < matrix.xLabels.length; x++)
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    color: heatmap ? Color.lerp(Colors.white, ColorPalette.primary, matrix.maxValue == 0 ? 0 : matrix.valueAt(x, y) / matrix.maxValue) : null,
                    child: Text(NumberFormat.compact().format(matrix.valueAt(x, y))),
                  ),
                ),
            ],
          ),
      ],
    ),
  );
}

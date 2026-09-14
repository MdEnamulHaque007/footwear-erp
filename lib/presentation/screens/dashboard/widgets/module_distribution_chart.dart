import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/color_palette.dart';
import '../../../../../domain/entities/dashboard/dashboard_chart_data_entity.dart';

/// Share of total records held by each module, as a pie of percentages.
class ModuleDistributionChart extends StatefulWidget {
  const ModuleDistributionChart({super.key, required this.points});

  final List<ChartDataPoint> points;

  @override
  State<ModuleDistributionChart> createState() =>
      _ModuleDistributionChartState();
}

class _ModuleDistributionChartState extends State<ModuleDistributionChart> {
  /// Index of the slice the pointer is over, or `-1`.
  int _touchedIndex = -1;

  /// Stable colour per module label so the pie matches the KPI cards.
  static const _colors = <String, Color>{
    'Master LC': ColorPalette.masterLc,
    'Purchase Order': ColorPalette.purchaseOrder,
    'Cutting': ColorPalette.cutting,
    'Sewing': ColorPalette.sewing,
    'Production': ColorPalette.production,
    'Issue': ColorPalette.issue,
    'Export': ColorPalette.export,
  };

  static Color _colorFor(String label) =>
      _colors[label] ?? ColorPalette.muted;

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
              'Module Distribution',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text('Share of all records', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            if (widget.points.isEmpty)
              SizedBox(
                height: 250,
                child: Center(
                  child: Text(
                    'No records yet.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 210,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 48,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          _touchedIndex =
                              response?.touchedSection?.touchedSectionIndex ??
                              -1;
                        });
                      },
                    ),
                    sections: [
                      for (var i = 0; i < widget.points.length; i++)
                        _section(i),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _legend(theme),
            ],
          ],
        ),
      ),
    );
  }

  PieChartSectionData _section(int index) {
    final point = widget.points[index];
    final touched = index == _touchedIndex;
    return PieChartSectionData(
      value: point.value,
      color: _colorFor(point.label),
      radius: touched ? 62 : 54,
      title: '${point.value.toStringAsFixed(0)}%',
      titleStyle: TextStyle(
        fontSize: touched ? 13 : 11,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _legend(ThemeData theme) => Wrap(
    spacing: 14,
    runSpacing: 8,
    children: [
      for (final point in widget.points)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _colorFor(point.label),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${point.label} · ${point.value.toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
    ],
  );
}

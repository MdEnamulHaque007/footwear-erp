import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/color_palette.dart';
import '../../../../../domain/entities/dashboard/dashboard_chart_data_entity.dart';

/// Multi-series line chart of daily quantity per production stage.
class ProductionTrendChart extends StatelessWidget {
  const ProductionTrendChart({super.key, required this.points});

  final List<MultiSeriesDataPoint> points;

  /// Series order and colour, matching the module palette.
  static const _series = <String, Color>{
    'Cutting': ColorPalette.cutting,
    'Sewing': ColorPalette.sewing,
    'Production': ColorPalette.production,
    'Issue': ColorPalette.issue,
    'Export': ColorPalette.export,
  };

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
              'Production Trend',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Last ${points.length} days',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (points.isEmpty)
              SizedBox(
                height: 240,
                child: Center(
                  child: Text(
                    'No activity in this period.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              SizedBox(height: 260, child: LineChart(_chartData(theme))),
            const SizedBox(height: 12),
            _legend(theme),
          ],
        ),
      ),
    );
  }

  LineChartData _chartData(ThemeData theme) {
    final maxY = _maxY();
    return LineChartData(
      minY: 0,
      maxY: maxY,
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY <= 0 ? 1 : maxY / 4,
        getDrawingHorizontalLine: (_) => FlLine(
          color: theme.dividerColor.withValues(alpha: 0.6),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: maxY <= 0 ? 1 : maxY / 4,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            // Thin the labels out so they never overlap on narrow screens.
            interval: (points.length / 6).clamp(1, 30).toDouble(),
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if (index < 0 || index >= points.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  points[index].label,
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => spots.map((spot) {
            final label = points[spot.x.round().clamp(0, points.length - 1)]
                .label;
            return LineTooltipItem(
              '$label\n${spot.y.toInt()}',
              TextStyle(
                color: spot.bar.color ?? theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            );
          }).toList(),
        ),
      ),
      lineBarsData: [
        for (final entry in _series.entries)
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].valueOf(entry.key)),
            ],
            color: entry.value,
            barWidth: 2,
            isCurved: true,
            curveSmoothness: 0.28,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: entry.value.withValues(alpha: 0.07),
            ),
          ),
      ],
    );
  }

  double _maxY() {
    var maxValue = 0.0;
    for (final point in points) {
      for (final key in _series.keys) {
        final value = point.valueOf(key);
        if (value > maxValue) maxValue = value;
      }
    }
    return maxValue <= 0 ? 10 : maxValue * 1.15;
  }

  Widget _legend(ThemeData theme) => Wrap(
    spacing: 14,
    runSpacing: 6,
    children: [
      for (final entry in _series.entries)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: entry.value,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(entry.key, style: theme.textTheme.bodySmall),
          ],
        ),
    ],
  );
}

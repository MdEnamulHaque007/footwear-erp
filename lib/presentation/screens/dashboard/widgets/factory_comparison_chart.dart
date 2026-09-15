import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/color_palette.dart';
import '../../../../../domain/entities/dashboard/dashboard_chart_data_entity.dart';

/// Total processed quantity per factory.
class FactoryComparisonChart extends StatelessWidget {
  const FactoryComparisonChart({super.key, required this.points});

  final List<ChartDataPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RepaintBoundary(
      child: Card(
        child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Factory Comparison',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Cutting + Sewing + Production',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (points.isEmpty)
              SizedBox(
                height: 250,
                child: Center(
                  child: Text(
                    'No factory data recorded.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              SizedBox(height: 250, child: BarChart(_chartData(theme))),
          ],
        ),
        ),
      ),
    );
  }

  BarChartData _chartData(ThemeData theme) {
    var maxValue = 0.0;
    for (final point in points) {
      if (point.value > maxValue) maxValue = point.value;
    }
    final maxY = maxValue <= 0 ? 10.0 : maxValue * 1.2;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) =>
              BarTooltipItem(
                '${points[group.x].label}\n'
                '${NumberFormat.decimalPattern().format(rod.toY.toInt())}',
                TextStyle(
                  color: theme.colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
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
            reservedSize: 42,
            interval: maxY / 4,
            getTitlesWidget: (value, meta) => Text(
              NumberFormat.compact().format(value),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 58,
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if (index < 0 || index >= points.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8, right: 4),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    points[index].label,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barGroups: [
        for (var i = 0; i < points.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: points[i].value,
                width: 22,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    ColorPalette.primary.withValues(alpha: 0.65),
                    ColorPalette.primary,
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

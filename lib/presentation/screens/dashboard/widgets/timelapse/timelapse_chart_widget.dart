import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/color_palette.dart';
import '../../../../../domain/entities/timelapse/timelapse_data_entity.dart';

class TimelapseChartWidget extends StatelessWidget {
  const TimelapseChartWidget({
    super.key,
    required this.data,
    required this.visiblePoints,
  });

  final TimelapseData data;
  final int visiblePoints;

  @override
  Widget build(BuildContext context) {
    if (data.totalPoints == 0) return const SizedBox.shrink();
    final playheadIndex =
        (visiblePoints - 1).clamp(0, data.totalPoints - 1).toInt();
    final playheadDate = data.series.isEmpty
        ? data.fromDate
        : data.series.first.points[playheadIndex].date;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cumulative ${data.series.isEmpty ? 'Data' : 'Timeline'}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Playhead: ${DateFormat('dd MMM yyyy').format(playheadDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(height: 300, child: LineChart(_chartData(context, playheadIndex))),
            const SizedBox(height: 12),
            _legend(context),
          ],
        ),
      ),
    );
  }

  LineChartData _chartData(BuildContext context, int playheadIndex) {
    final maxY = _maxY();
    return LineChartData(
      minX: 0,
      maxX: (data.totalPoints - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (_) => FlLine(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.65),
        ),
      ),
      borderData: FlBorderData(show: false),
      extraLinesData: ExtraLinesData(
        verticalLines: [
          VerticalLine(
            x: playheadIndex.toDouble(),
            color: Colors.grey,
            strokeWidth: 1.5,
            dashArray: [6, 5],
          ),
        ],
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 46,
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
            reservedSize: 30,
            interval: (data.totalPoints / 6).clamp(1, 31).toDouble(),
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if (index < 0 || index >= data.totalPoints) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  DateFormat('dd MMM').format(data.series.first.points[index].date),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        for (final series in data.series)
          LineChartBarData(
            spots: [
              for (var index = 0; index < visiblePoints && index < series.points.length; index++)
                FlSpot(index.toDouble(), series.points[index].value),
            ],
            color: _color(series.department.label),
            barWidth: 2.5,
            isCurved: true,
            curveSmoothness: 0.22,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _color(series.department.label).withValues(alpha: 0.06),
            ),
          ),
      ],
    );
  }

  double _maxY() {
    var max = 0.0;
    for (final series in data.series) {
      for (final point in series.points.take(visiblePoints)) {
        if (point.value > max) max = point.value;
      }
    }
    return max <= 0 ? 10 : max * 1.15;
  }

  Widget _legend(BuildContext context) => Wrap(
    spacing: 14,
    runSpacing: 6,
    children: [
      for (final series in data.series)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _color(series.department.label),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(series.department.label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
    ],
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

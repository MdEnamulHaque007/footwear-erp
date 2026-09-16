import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../domain/entities/dashboard/dashboard_chart_data_entity.dart';
import '../shared/dashboard_card.dart';
import '../shared/section_header.dart';

class TimelapseProductionChart extends StatelessWidget {
  const TimelapseProductionChart({super.key, required this.points});
  final List<MultiSeriesDataPoint> points;
  static const _series = <String, Color>{'Cutting': Color(0xFF1976D2), 'Sewing': Color(0xFF7B1FA2), 'Production': Color(0xFFF57C00), 'Export': Color(0xFF2E7D32)};
  @override
  Widget build(BuildContext context) => DashboardCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SectionHeader(title: 'Time-Lapse Production Report', subtitle: 'Last 30 days'),
    const SizedBox(height: 12),
    Wrap(spacing: 12, runSpacing: 6, children: _series.entries.map((entry) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 9, height: 9, decoration: BoxDecoration(color: entry.value, shape: BoxShape.circle)), const SizedBox(width: 5), Text(entry.key, style: Theme.of(context).textTheme.bodySmall)])).toList()),
    const SizedBox(height: 14),
    SizedBox(height: 255, child: RepaintBoundary(child: points.isEmpty ? const Center(child: Text('No production data for this period')) : LineChart(_data()))),
  ]));

  LineChartData _data() {
    final maximum = points.expand((point) => _series.keys.map(point.valueOf)).fold<double>(1, (a, b) => a > b ? a : b);
    return LineChartData(
      minY: 0, maxY: maximum * 1.12,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(), rightTitles: const AxisTitles(),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 42, getTitlesWidget: (value, _) => Text(_compact(value), style: const TextStyle(fontSize: 10)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 5, getTitlesWidget: (value, _) { final index = value.toInt(); return Padding(padding: const EdgeInsets.only(top: 8), child: Text(index >= 0 && index < points.length ? points[index].label : '', style: const TextStyle(fontSize: 10))); })),
      ),
      lineBarsData: _series.entries.map((entry) => LineChartBarData(
        isCurved: true, color: entry.value, barWidth: 2.5, dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: entry.value.withValues(alpha: .08)),
        spots: [for (var index = 0; index < points.length; index++) FlSpot(index.toDouble(), points[index].valueOf(entry.key))],
      )).toList(),
    );
  }
  static String _compact(double value) => value >= 1000 ? '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k' : value.toStringAsFixed(0);
}

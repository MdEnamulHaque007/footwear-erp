import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../domain/entities/dashboard/dashboard_chart_data_entity.dart';
import '../shared/dashboard_card.dart';
import '../shared/section_header.dart';

class DepartmentPerformanceChart extends StatelessWidget {
  const DepartmentPerformanceChart({super.key, required this.points});
  final List<MultiSeriesDataPoint> points;
  @override
  Widget build(BuildContext context) {
    final items = points.length <= 6 ? points : points.sublist(points.length - 6);
    final values = items.map((item) => item.valueOf('Production'));
    final max = values.fold<double>(1, (value, item) => value > item ? value : item);
    return DashboardCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Department Performance', subtitle: 'Daily output vs target'),
      const SizedBox(height: 12),
      Row(children: const [
        _Legend(color: Color(0xFF90CAF9), label: 'Daily'), SizedBox(width: 12), _Legend(color: Color(0xFF1976D2), label: 'Target'),
      ]),
      const SizedBox(height: 12),
      SizedBox(height: 255, child: RepaintBoundary(child: items.isEmpty ? const Center(child: Text('No production data')) : BarChart(_data(items, max)))),
    ]));
  }
  BarChartData _data(List<MultiSeriesDataPoint> items, double max) => BarChartData(
    maxY: 110, alignment: BarChartAlignment.spaceAround, borderData: FlBorderData(show: false), gridData: const FlGridData(drawVerticalLine: false),
    titlesData: FlTitlesData(topTitles: const AxisTitles(), rightTitles: const AxisTitles(), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 20, getTitlesWidget: (value, _) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)))), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, _) { final index = value.toInt(); return Padding(padding: const EdgeInsets.only(top: 8), child: Text(index < items.length ? _short(items[index].label) : '', style: const TextStyle(fontSize: 10))); }))),
    barGroups: [for (var index = 0; index < items.length; index++) BarChartGroupData(x: index, barsSpace: 4, barRods: [BarChartRodData(toY: (items[index].valueOf('Production') / max) * 100, color: const Color(0xFF90CAF9), width: 10, borderRadius: BorderRadius.circular(3)), BarChartRodData(toY: 85, color: const Color(0xFF1976D2), width: 10, borderRadius: BorderRadius.circular(3))])],
  );
  static String _short(String value) => value.length <= 7 ? value : value.substring(0, 7);
}
class _Legend extends StatelessWidget { const _Legend({required this.color, required this.label}); final Color color; final String label; @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 9, height: 9, color: color), const SizedBox(width: 4), Text(label, style: Theme.of(context).textTheme.bodySmall)]); }

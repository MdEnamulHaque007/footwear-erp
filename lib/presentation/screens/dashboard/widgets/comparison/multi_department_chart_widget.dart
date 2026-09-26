/// ============================================================================
/// ফাইল: lib/presentation/screens/dashboard/widgets/comparison/multi_department_chart_widget.dart
/// স্তর: Presentation Screen | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: MultiDepartmentChartWidget, _ChartCard, _RadarPainter
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/color_palette.dart';
import '../../../../../domain/entities/dashboard/comparison_item_entity.dart';

class MultiDepartmentChartWidget extends StatelessWidget {
  const MultiDepartmentChartWidget({super.key, required this.results});

  final List<ComparisonResult> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('No comparison data is available.')),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (results.length == 1) {
          return _ChartCard(result: results.first);
        }
        if (results.length >= 5) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final result in results)
                  SizedBox(
                    width: 340,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _ChartCard(result: result),
                    ),
                  ),
              ],
            ),
          );
        }
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final result in results)
              SizedBox(width: width, child: _ChartCard(result: result)),
          ],
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.result});

  final ComparisonResult result;

  @override
  Widget build(BuildContext context) {
    final data = result.data;
    final color = _color(result.item.department.label);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(result.item.department.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.item.department.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(result.item.chartType.label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '${DateFormat('dd MMM yy').format(data.fromDate)} – ${DateFormat('dd MMM yy').format(data.toDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            if (data.monthlyData.isEmpty)
              const SizedBox(height: 190, child: Center(child: Text('No records in this range.')))
            else
              SizedBox(height: 190, child: _chart(color)),
            const SizedBox(height: 8),
            Text(
              'Total: ${NumberFormat.decimalPattern().format(data.totalQuantity)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chart(Color color) => switch (result.item.chartType) {
    ChartType.line => LineChart(_lineData(color, area: false)),
    ChartType.area => LineChart(_lineData(color, area: true)),
    ChartType.bar => BarChart(_barData(color)),
    ChartType.pie => PieChart(_pieData(color)),
    ChartType.radar => CustomPaint(painter: _RadarPainter(result.data.monthlyData.map((e) => e.quantity.toDouble()).toList(), color)),
  };

  LineChartData _lineData(Color color, {required bool area}) {
    final values = result.data.monthlyData;
    final maxY = _maxValue() * 1.15;
    return LineChartData(
      minY: 0,
      maxY: maxY <= 0 ? 10 : maxY,
      gridData: FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: const AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if (index < 0 || index >= values.length) return const SizedBox.shrink();
              return Text(DateFormat('MMM').format(values[index].monthDate), style: const TextStyle(fontSize: 9));
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i].quantity.toDouble())],
          color: color,
          isCurved: true,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: area, color: color.withValues(alpha: 0.18)),
        ),
      ],
    );
  }

  BarChartData _barData(Color color) => BarChartData(
    alignment: BarChartAlignment.spaceAround,
    borderData: FlBorderData(show: false),
    gridData: const FlGridData(show: false),
    titlesData: const FlTitlesData(show: false),
    barGroups: [
      for (var i = 0; i < result.data.monthlyData.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: result.data.monthlyData[i].quantity.toDouble(), color: color, width: 14)],
        ),
    ],
  );

  PieChartData _pieData(Color color) => PieChartData(
    sectionsSpace: 2,
    centerSpaceRadius: 24,
    sections: [
      for (var i = 0; i < result.data.monthlyData.length; i++)
        PieChartSectionData(
          value: result.data.monthlyData[i].quantity.toDouble(),
          color: color.withValues(alpha: 1 - (i % 4) * 0.13),
          radius: 48,
          title: DateFormat('MMM').format(result.data.monthlyData[i].monthDate),
          titleStyle: const TextStyle(fontSize: 9, color: Colors.white),
        ),
    ],
  );

  double _maxValue() => result.data.monthlyData.fold<double>(
    0,
    (maximum, item) => item.quantity > maximum ? item.quantity.toDouble() : maximum,
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

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.36;
    final count = math.max(values.length, 3);
    final maxValue = values.fold<double>(
      0,
      (maximum, value) => value > maximum ? value : maximum,
    );
    final grid = Paint()..color = color.withValues(alpha: 0.22)..style = PaintingStyle.stroke;
    final shape = Path();
    for (var index = 0; index < count; index++) {
      final angle = -math.pi / 2 + (2 * math.pi * index / count);
      final point = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      if (index == 0) {
        shape.moveTo(point.dx, point.dy);
      } else {
        shape.lineTo(point.dx, point.dy);
      }
    }
    shape.close();
    canvas.drawPath(shape, grid);
    final dataPath = Path();
    for (var index = 0; index < count; index++) {
      final fraction = index < values.length && maxValue > 0 ? values[index] / maxValue : 0;
      final angle = -math.pi / 2 + (2 * math.pi * index / count);
      final point = Offset(center.dx + radius * fraction * math.cos(angle), center.dy + radius * fraction * math.sin(angle));
      if (index == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => oldDelegate.values != values || oldDelegate.color != color;
}

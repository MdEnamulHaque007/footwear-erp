import 'package:flutter/material.dart';
import '../../../../../domain/entities/dashboard/dashboard_chart_data_entity.dart';
import '../shared/dashboard_card.dart';
import '../shared/section_header.dart';

class ProductionEfficiencyTable extends StatelessWidget {
  const ProductionEfficiencyTable({super.key, required this.factories});
  final List<ChartDataPoint> factories;
  @override
  Widget build(BuildContext context) {
    final rows = factories.take(5).toList();
    final max = rows.fold<double>(1, (current, row) => current > row.value ? current : row.value);
    return DashboardCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Production Efficiency', subtitle: 'Factory-wise process completion'),
      const SizedBox(height: 14),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
        columnSpacing: 12, headingRowHeight: 34,
        columns: const [DataColumn(label: Text('Factory')), DataColumn(label: Text('Cut')), DataColumn(label: Text('Sew')), DataColumn(label: Text('Last')), DataColumn(label: Text('Export'))],
        rows: rows.isEmpty ? const [] : rows.map((row) { final percentage = ((row.value / max) * 100).round(); return DataRow(cells: [DataCell(Text(row.label)), DataCell(_cell(percentage)), DataCell(_cell((percentage * .94).round())), DataCell(_cell((percentage * .86).round())), DataCell(_cell((percentage * .72).round()))]); }).toList(),
      )),
      if (rows.isEmpty) const Padding(padding: EdgeInsets.all(18), child: Center(child: Text('No factory data available'))),
    ]));
  }
  Widget _cell(int value) { final color = value >= 100 ? const Color(0xFF4CAF50) : value >= 60 ? const Color(0xFFFF9800) : const Color(0xFFF44336); return Container(alignment: Alignment.center, width: 40, padding: const EdgeInsets.symmetric(vertical: 5), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)), child: Text('$value%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))); }
}

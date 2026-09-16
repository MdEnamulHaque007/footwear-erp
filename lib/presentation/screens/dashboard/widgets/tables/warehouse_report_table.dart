import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../domain/entities/dashboard/dashboard_stats_entity.dart';
import '../../../../routes/route_constants.dart';
import '../shared/dashboard_card.dart';
import '../shared/section_header.dart';

class WarehouseReportTable extends StatelessWidget {
  const WarehouseReportTable({super.key, required this.stats});
  final DashboardStatsEntity stats;
  @override
  Widget build(BuildContext context) {
    final number = NumberFormat.decimalPattern();
    return DashboardCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: 'Production Warehouse Report', subtitle: 'Live production summary', action: TextButton.icon(onPressed: () => context.go(RouteConstants.warehouseReport), icon: const Icon(Icons.open_in_new, size: 16), label: const Text('Open full report'))),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(onPressed: () => context.go(RouteConstants.warehouseReport), icon: const Icon(Icons.date_range_outlined, size: 16), label: const Text('Date range')),
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.group_work_outlined, size: 16), label: const Text('Group by: Article')),
        FilledButton.tonalIcon(onPressed: () => context.go(RouteConstants.warehouseReport), icon: const Icon(Icons.file_download_outlined, size: 16), label: const Text('Export')),
      ]),
      const SizedBox(height: 12),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
        headingRowColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.surfaceContainerHighest),
        columns: const [DataColumn(label: Text('Period')), DataColumn(label: Text('PO Qty'), numeric: true), DataColumn(label: Text('Cutting'), numeric: true), DataColumn(label: Text('Sewing'), numeric: true), DataColumn(label: Text('Lasting'), numeric: true), DataColumn(label: Text('Warehouse'), numeric: true)],
        rows: [DataRow(cells: [
          const DataCell(Text('Current totals')),
          DataCell(Text(number.format(stats.poCount))),
          DataCell(Text(number.format(stats.cuttingQuantity))),
          DataCell(Text(number.format(stats.sewingQuantity))),
          DataCell(Text(number.format(stats.productionQuantity))),
          DataCell(Text(number.format((stats.productionQuantity - stats.exportQuantity).clamp(0, 1 << 62)))),
        ])],
      )),
    ]));
  }
}

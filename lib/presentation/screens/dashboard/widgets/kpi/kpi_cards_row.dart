import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../domain/entities/dashboard/dashboard_stats_entity.dart';
import 'kpi_card_widget.dart';

class KpiCardsRow extends StatelessWidget {
  const KpiCardsRow({super.key, required this.stats});
  final DashboardStatsEntity stats;
  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.decimalPattern();
    final cards = [
      KpiCardWidget(title: 'Total Footwear Produced', value: format.format(stats.productionQuantity), subtitle: 'Pairs • YTD', icon: Icons.emoji_people_outlined, color: const Color(0xFFE3F2FD)),
      KpiCardWidget(title: 'Pending POs', value: format.format(stats.poCount), subtitle: 'Orders requiring attention', icon: Icons.inventory_2_outlined, color: const Color(0xFFFFF3E0)),
      KpiCardWidget(title: 'Cutting Completed', value: format.format(stats.cuttingQuantity), subtitle: 'Pairs processed', icon: Icons.content_cut, color: const Color(0xFFF3E5F5)),
      KpiCardWidget(title: 'Sewing Completed', value: format.format(stats.sewingQuantity), subtitle: 'Pairs processed', icon: Icons.weekend_outlined, color: const Color(0xFFE8F5E9)),
      KpiCardWidget(title: 'Exported This Month', value: format.format(stats.exportQuantity), subtitle: 'Pairs shipped', icon: Icons.local_shipping_outlined, color: const Color(0xFFFCE4EC)),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1200 ? 5 : constraints.maxWidth >= 700 ? 3 : 1;
      return GridView.count(crossAxisCount: columns, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: columns == 1 ? 3 : 1.8, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: cards);
    });
  }
}

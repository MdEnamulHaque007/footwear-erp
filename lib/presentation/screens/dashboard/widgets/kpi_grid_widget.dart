import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../domain/entities/dashboard/dashboard_stats_entity.dart';
import 'kpi_stat_card_widget.dart';

/// The eight-module KPI row.
///
/// Column count steps down with the viewport: 4 on desktop, 2 on tablet, 1 on
/// mobile, so the cards never squeeze below a readable width.
class KpiGridWidget extends StatelessWidget {
  const KpiGridWidget({super.key, required this.stats});

  final DashboardStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    final cards = _cards(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 4
            : width >= 640
            ? 2
            : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: columns == 1 ? 3.2 : 1.55,
          children: cards,
        );
      },
    );
  }

  List<Widget> _cards(BuildContext context) {
    void go(String route) => context.go(route);
    return [
      KpiStatCardWidget(
        emoji: '📄',
        icon: Icons.description,
        title: 'Master LC',
        count: stats.masterLcCount,
        value: stats.masterLcValue,
        valueIsCurrency: true,
        color: ColorPalette.masterLc,
        onTap: () => go('/master-lc'),
      ),
      KpiStatCardWidget(
        emoji: '🧾',
        icon: Icons.receipt_long,
        title: 'Purchase Orders',
        count: stats.poCount,
        value: stats.poValue,
        valueIsCurrency: true,
        color: ColorPalette.purchaseOrder,
        onTap: () => go('/purchase-orders'),
      ),
      KpiStatCardWidget(
        emoji: '✂️',
        icon: Icons.content_cut,
        title: 'Cutting',
        count: stats.cuttingCount,
        value: stats.cuttingQuantity.toDouble(),
        color: ColorPalette.cutting,
        onTap: () => go('/cutting'),
      ),
      KpiStatCardWidget(
        emoji: '🧵',
        icon: Icons.gesture,
        title: 'Sewing',
        count: stats.sewingCount,
        value: stats.sewingQuantity.toDouble(),
        color: ColorPalette.sewing,
        onTap: () => go('/sewing'),
      ),
      KpiStatCardWidget(
        emoji: '🏭',
        icon: Icons.precision_manufacturing,
        title: 'Production',
        count: stats.productionCount,
        value: stats.productionQuantity.toDouble(),
        color: ColorPalette.production,
        onTap: () => go('/production'),
      ),
      KpiStatCardWidget(
        emoji: '📦',
        icon: Icons.outbox,
        title: 'Issue',
        count: stats.issueCount,
        value: stats.issueQuantity.toDouble(),
        color: ColorPalette.issue,
        onTap: () => go('/issue'),
      ),
      KpiStatCardWidget(
        emoji: '🚢',
        icon: Icons.local_shipping,
        title: 'Export',
        count: stats.exportCount,
        value: stats.exportQuantity.toDouble(),
        color: ColorPalette.export,
        onTap: () => go('/export'),
      ),
      KpiStatCardWidget(
        emoji: '👥',
        icon: Icons.people_alt,
        title: 'Users',
        count: stats.userCount,
        value: stats.activeUserCount.toDouble(),
        color: ColorPalette.info,
        onTap: () => go('/admin/users'),
      ),
    ];
  }
}

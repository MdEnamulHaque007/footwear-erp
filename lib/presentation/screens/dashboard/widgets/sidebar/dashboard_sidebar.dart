import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes/route_constants.dart';
import 'sidebar_menu_item.dart';
import 'sidebar_user_profile.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => ColoredBox(color: const Color(0xFF1A2332), child: SafeArea(child: Column(children: [
    Padding(padding: const EdgeInsets.all(20), child: Row(children: [
      const Icon(Icons.precision_manufacturing_outlined, color: Colors.white),
      if (!compact) ...[const SizedBox(width: 10), const Expanded(child: Text('FOOTWEAR ERP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)))],
    ])),
    Expanded(child: ListView(children: [
      SidebarMenuItem(icon: Icons.dashboard_outlined, label: 'Dashboard', active: true, compact: compact, onTap: () => context.go(RouteConstants.dashboard)),
      SidebarMenuItem(icon: Icons.inventory_2_outlined, label: 'Inventory Management', compact: compact, onTap: () => context.go('/master-lc')),
      _label('PRODUCTION'),
      SidebarMenuItem(icon: Icons.content_cut, label: 'Cutting', compact: compact, indent: true, onTap: () => context.go('/cutting')),
      SidebarMenuItem(icon: Icons.weekend_outlined, label: 'Sewing', compact: compact, indent: true, onTap: () => context.go('/sewing')),
      SidebarMenuItem(icon: Icons.factory_outlined, label: 'Production', compact: compact, indent: true, onTap: () => context.go('/production')),
      SidebarMenuItem(icon: Icons.inventory_outlined, label: 'Issue', compact: compact, indent: true, onTap: () => context.go('/issue')),
      SidebarMenuItem(icon: Icons.local_shipping_outlined, label: 'Export', compact: compact, indent: true, onTap: () => context.go('/export')),
      _label('WAREHOUSE REPORTS'),
      SidebarMenuItem(icon: Icons.table_chart_outlined, label: 'Production Report', compact: compact, indent: true, onTap: () => context.go(RouteConstants.productionReport)),
      SidebarMenuItem(icon: Icons.inventory_2_outlined, label: 'Finished Goods', compact: compact, indent: true, onTap: () => context.go(RouteConstants.finishedGoodsReport)),
      SidebarMenuItem(icon: Icons.warehouse_outlined, label: 'WH Report', compact: compact, indent: true, onTap: () => context.go(RouteConstants.warehouseReport)),
      _label('MANAGEMENT'),
      SidebarMenuItem(icon: Icons.people_outline, label: 'Users', compact: compact, onTap: () => context.go(RouteConstants.adminUsers)),
      SidebarMenuItem(icon: Icons.history, label: 'Audit Log', compact: compact, onTap: () => context.go(RouteConstants.auditLog)),
      SidebarMenuItem(icon: Icons.settings_outlined, label: 'Settings', compact: compact, onTap: () => context.go(RouteConstants.settings)),
    ])),
    SidebarUserProfile(compact: compact),
  ])));
  Widget _label(String value) => compact ? const SizedBox(height: 12) : Padding(padding: const EdgeInsets.fromLTRB(20, 18, 12, 6), child: Text(value, style: const TextStyle(color: Color(0xFF718096), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)));
}

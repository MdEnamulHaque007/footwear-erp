/// ============================================================================
/// ফাইল: lib/presentation/screens/reports/reports_screen.dart
/// স্তর: Presentation Screen | মডিউল: Reports
/// উদ্দেশ্য: Reports মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: ReportsScreen
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/color_palette.dart';
import '../../routes/route_constants.dart';
import '../../widgets/empty_state.dart';

/// Placeholder for the Reports module so the drawer's "Reports" link resolves
/// instead of falling through to the "Page not found" error builder.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static const _plannedReports = <String>[
    '📦 Stock Report',
    '💰 Financial Report',
    '📄 PO Report',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: ColorPalette.reports,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Dashboard',
          onPressed: () => context.go(RouteConstants.dashboard),
        ),
      ),
      body: EmptyState(
        icon: Icons.bar_chart,
        iconColor: ColorPalette.reports,
        title: '📈 Reports',
        subtitle: 'Select a report to generate.',
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: () => context.push(RouteConstants.productionReport),
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('📊 Production Warehouse Report'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push(RouteConstants.finishedGoodsReport),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('📦 Finished Goods Report'),
            ),
            const SizedBox(height: 24),
            Text(
              'Planned reports',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: ColorPalette.reports,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (final report in _plannedReports)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  report,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

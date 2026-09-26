/// ============================================================================
/// ফাইল: lib/presentation/screens/dashboard/widgets/recent_activities_widget.dart
/// স্তর: Presentation Screen | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: RecentActivitiesWidget
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../domain/entities/dashboard/dashboard_activity_entity.dart';

/// Newest ten entries merged from every production collection.
class RecentActivitiesWidget extends StatelessWidget {
  const RecentActivitiesWidget({super.key, required this.activities});

  final List<DashboardActivityEntity> activities;

  /// Icon, colour and destination per module key.
  static const _meta = <String, (IconData, Color, String)>{
    'master_lc': (Icons.description, ColorPalette.masterLc, '/master-lc'),
    'purchase_order': (
      Icons.receipt_long,
      ColorPalette.purchaseOrder,
      '/purchase-orders',
    ),
    'cutting': (Icons.content_cut, ColorPalette.cutting, '/cutting'),
    'sewing': (Icons.gesture, ColorPalette.sewing, '/sewing'),
    'production': (
      Icons.precision_manufacturing,
      ColorPalette.production,
      '/production',
    ),
    'issue': (Icons.outbox, ColorPalette.issue, '/issue'),
    'export': (Icons.local_shipping, ColorPalette.export, '/export'),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Activities',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${activities.length} latest',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activities.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No recent activity.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              for (var i = 0; i < activities.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _row(context, theme, activities[i]),
              ],
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    ThemeData theme,
    DashboardActivityEntity activity,
  ) {
    final meta = _meta[activity.module];
    final icon = meta?.$1 ?? Icons.circle;
    final color = meta?.$2 ?? ColorPalette.muted;
    final route = meta?.$3;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: route == null ? null : () => context.go(route),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        activity.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        activity.relativeTime,
        style: theme.textTheme.bodySmall,
      ),
      trailing: route == null
          ? null
          : const Icon(Icons.chevron_right, size: 18),
    );
  }
}

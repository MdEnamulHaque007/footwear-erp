/// ============================================================================
/// ফাইল: lib/presentation/screens/dashboard/widgets/quick_actions_widget.dart
/// স্তর: Presentation Screen | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: QuickActionsWidget
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/color_palette.dart';

/// Horizontal shortcut strip that jumps straight into each module's create form.
class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  /// Label, emoji, destination and colour per action.
  static const _actions = <(String, String, String, Color)>[
    ('New Master LC', '📄', '/master-lc/new', ColorPalette.masterLc),
    ('New PO', '🧾', '/purchase-orders/new', ColorPalette.purchaseOrder),
    ('New Cutting', '✂️', '/cutting/new', ColorPalette.cutting),
    ('New Sewing', '🧵', '/sewing/new', ColorPalette.sewing),
    ('New Production', '🏭', '/production/new', ColorPalette.production),
    ('New Issue', '📦', '/issue/new', ColorPalette.issue),
    ('New Export', '🚢', '/export/new', ColorPalette.export),
    ('Users', '👥', '/admin/users', ColorPalette.info),
    ('Reports', '📊', '/reports', ColorPalette.reports),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text('Jump straight to a form', style: theme.textTheme.bodySmall),
            const SizedBox(height: 14),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _actions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final action = _actions[index];
                  return _tile(context, action);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, (String, String, String, Color) action) {
    final (label, emoji, route, color) = action;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push(route),
      child: Container(
        width: 104,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

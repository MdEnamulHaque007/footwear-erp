import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../../domain/entities/dashboard/dashboard_quick_stats_entity.dart';

/// Today / This week / This month totals.
class QuickStatsWidget extends StatelessWidget {
  const QuickStatsWidget({super.key, required this.stats});

  final DashboardQuickStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _PeriodCard(
        label: 'Today',
        emoji: '☀️',
        quantity: stats.todayQuantity,
        color: ColorPalette.success,
      ),
      _PeriodCard(
        label: 'This Week',
        emoji: '📅',
        quantity: stats.weekQuantity,
        trend: stats.weekTrend,
        color: ColorPalette.info,
      ),
      _PeriodCard(
        label: 'This Month',
        emoji: '🗓️',
        quantity: stats.monthQuantity,
        color: ColorPalette.secondary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720
            ? 3
            : constraints.maxWidth >= 460
            ? 2
            : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: columns == 1 ? 3.4 : 1.9,
          children: cards,
        );
      },
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.label,
    required this.emoji,
    required this.quantity,
    required this.color,
    this.trend,
  });

  final String label;
  final String emoji;
  final int quantity;
  final Color color;

  /// Optional percentage used for the trend arrow.
  final double? trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = trend;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (value != null && value != 0)
                Icon(
                  value >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 18,
                  color: value >= 0
                      ? ColorPalette.success
                      : ColorPalette.error,
                ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              NumberFormat.decimalPattern().format(quantity),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          Text('pieces', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

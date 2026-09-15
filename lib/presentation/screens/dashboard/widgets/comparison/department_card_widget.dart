import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/color_palette.dart';
import '../../../../../domain/entities/dashboard/comparison_item_entity.dart';
import '../../../../../domain/entities/dashboard/department_option_entity.dart';
import 'department_selector.dart';

class DepartmentCardWidget extends StatelessWidget {
  const DepartmentCardWidget({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
    required this.canRemove,
  });

  final int index;
  final ComparisonItem item;
  final ValueChanged<ComparisonItem> onChanged;
  final VoidCallback onRemove;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final color = _color(item.department.label);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Department ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                tooltip: 'Remove department',
                onPressed: canRemove ? onRemove : null,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          DepartmentSelector(
            title: 'Department ${index + 1}',
            selectedLabel: item.department.label,
            accent: color,
            onChanged: (label) => onChanged(
              item.copyWith(department: DepartmentOption.fromLabel(label)),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _dateButton(
                context,
                label: 'From',
                value: item.fromDate,
                onPicked: (date) => onChanged(item.copyWith(fromDate: date)),
              ),
              _dateButton(
                context,
                label: 'To',
                value: item.toDate,
                onPicked: (date) => onChanged(item.copyWith(toDate: date)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ChartType>(
            key: ValueKey('${item.id}-${item.chartType}'),
            initialValue: item.chartType,
            decoration: const InputDecoration(labelText: 'Chart type'),
            items: [
              for (final chartType in ChartType.values)
                DropdownMenuItem(value: chartType, child: Text(chartType.label)),
            ],
            onChanged: (type) {
              if (type != null) onChanged(item.copyWith(chartType: type));
            },
          ),
        ],
      ),
    );
  }

  Widget _dateButton(
    BuildContext context, {
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onPicked,
  }) => OutlinedButton.icon(
    onPressed: () async {
      final date = await showDatePicker(
        context: context,
        initialDate: value,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (date != null) onPicked(date);
    },
    icon: const Icon(Icons.calendar_today_outlined, size: 16),
    label: Text('$label: ${DateFormat('dd MMM yyyy').format(value)}'),
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

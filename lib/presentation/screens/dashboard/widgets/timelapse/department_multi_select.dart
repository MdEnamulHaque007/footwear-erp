import 'package:flutter/material.dart';

import '../../../../../core/theme/color_palette.dart';
import '../../../../../domain/entities/dashboard/department_option_entity.dart';

class DepartmentMultiSelect extends StatelessWidget {
  const DepartmentMultiSelect({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final List<DepartmentOption> selected;
  final ValueChanged<List<DepartmentOption>> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final department in DepartmentOption.all)
        FilterChip(
          label: Text('${department.emoji} ${department.label}'),
          selected: selected.contains(department),
          selectedColor: _color(department).withValues(alpha: 0.18),
          checkmarkColor: _color(department),
          onSelected: (isSelected) {
            final next = [...selected];
            if (isSelected) {
              next.add(department);
            } else {
              next.remove(department);
            }
            onChanged(next);
          },
        ),
    ],
  );

  static Color _color(DepartmentOption department) => switch (department.label) {
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

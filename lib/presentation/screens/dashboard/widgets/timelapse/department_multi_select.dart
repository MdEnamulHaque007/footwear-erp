/// ============================================================================
/// ফাইল: lib/presentation/screens/dashboard/widgets/timelapse/department_multi_select.dart
/// স্তর: Presentation Screen | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: DepartmentMultiSelect
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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

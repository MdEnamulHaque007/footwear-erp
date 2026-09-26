/// ============================================================================
/// ফাইল: lib/presentation/screens/dashboard/widgets/comparison/department_selector.dart
/// স্তর: Presentation Screen | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: DepartmentSelector
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';

import '../../../../../core/theme/color_palette.dart';
import '../../../../../domain/entities/dashboard/department_option_entity.dart';

/// Dropdown for choosing one of the seven comparable departments.
///
/// Backed by [DepartmentOption.all], so adding a stage to that list makes it
/// selectable here without touching this widget.
class DepartmentSelector extends StatelessWidget {
  const DepartmentSelector({
    super.key,
    required this.title,
    required this.selectedLabel,
    required this.onChanged,
    this.accent = ColorPalette.primary,
  });

  /// Card heading, e.g. `Side A`.
  final String title;

  /// Currently selected department label.
  final String selectedLabel;

  final ValueChanged<String> onChanged;

  /// Colour used for the badge, so the two sides are visually distinct.
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: selectedLabel,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Department',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            for (final option in DepartmentOption.all)
              DropdownMenuItem<String>(
                value: option.label,
                child: Row(
                  children: [
                    Text(option.emoji),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}

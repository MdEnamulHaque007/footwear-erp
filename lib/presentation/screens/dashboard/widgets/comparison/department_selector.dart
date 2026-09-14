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

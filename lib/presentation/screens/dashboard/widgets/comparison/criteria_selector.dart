/// ============================================================================
/// ফাইল: lib/presentation/screens/dashboard/widgets/comparison/criteria_selector.dart
/// স্তর: Presentation Screen | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: CriteriaSelector
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';

import '../../../../../domain/entities/dashboard/criteria_option_entity.dart';

class CriteriaSelector extends StatelessWidget {
  const CriteriaSelector({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
    this.options = CriteriaOption.all,
  });

  final String label;
  final CriteriaOption selected;
  final ValueChanged<CriteriaOption> onChanged;
  final List<CriteriaOption> options;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<CriteriaOption>(
    key: ValueKey(selected.field),
    initialValue: selected,
    isExpanded: true,
    decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    items: options
        .map(
          (option) => DropdownMenuItem(
            value: option,
            child: Text('${option.icon} ${option.label}', overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: (option) {
      if (option != null) onChanged(option);
    },
  );
}

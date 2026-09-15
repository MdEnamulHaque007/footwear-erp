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

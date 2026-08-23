import 'package:flutter/material.dart';

class CascadingDropdown<T> extends StatelessWidget {
  const CascadingDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
  });
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? label;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    items: items,
    onChanged: onChanged,
    decoration: InputDecoration(labelText: label),
  );
}

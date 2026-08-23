import 'package:flutter/material.dart';

class PermissionCheckboxWidget extends StatelessWidget {
  const PermissionCheckboxWidget({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: value,
    onChanged: (value) => onChanged(value ?? false),
    title: Text(label),
    dense: true,
    controlAffinity: ListTileControlAffinity.leading,
  );
}

import 'package:flutter/material.dart';

class PermissionToggle extends StatelessWidget {
  const PermissionToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) =>
      Switch(value: value, onChanged: onChanged);
}

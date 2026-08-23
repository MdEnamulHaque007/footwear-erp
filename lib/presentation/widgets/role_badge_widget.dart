import 'package:flutter/material.dart';

class RoleBadgeWidget extends StatelessWidget {
  const RoleBadgeWidget({super.key, required this.role});
  final String role;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(role.toUpperCase()),
    visualDensity: VisualDensity.compact,
  );
}

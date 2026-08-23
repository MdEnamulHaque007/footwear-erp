import 'package:flutter/material.dart';

class UserStatusWidget extends StatelessWidget {
  const UserStatusWidget({super.key, required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => Text(
    active ? 'Active' : 'Inactive',
    style: TextStyle(
      color: active ? Colors.green : Colors.red,
      fontWeight: FontWeight.w600,
    ),
  );
}

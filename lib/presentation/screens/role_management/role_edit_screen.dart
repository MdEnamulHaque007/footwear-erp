import 'package:flutter/material.dart';

class RoleEditScreen extends StatelessWidget {
  const RoleEditScreen({super.key, this.roleId});
  final String? roleId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit role')),
    body: Center(child: Text(roleId ?? 'Role')),
  );
}

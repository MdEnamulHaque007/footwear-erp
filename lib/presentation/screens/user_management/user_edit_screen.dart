import 'package:flutter/material.dart';

class UserEditScreen extends StatelessWidget {
  const UserEditScreen({super.key, this.uid});
  final String? uid;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit user')),
    body: Center(child: Text(uid ?? 'User')),
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Access denied')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('You do not have permission to view this page.'),
          TextButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Back to dashboard'),
          ),
        ],
      ),
    ),
  );
}

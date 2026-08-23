import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MasterLCDetailScreen extends StatelessWidget {
  const MasterLCDetailScreen({super.key, required this.tag});
  final String tag;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Master LC: $tag')),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.push('/purchase-orders/new'),
      child: const Icon(Icons.add),
    ),
    body: Center(child: Text('Purchase orders for $tag')),
  );
}

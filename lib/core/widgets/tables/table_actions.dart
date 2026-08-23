import 'package:flutter/material.dart';

class TableActions extends StatelessWidget {
  const TableActions({super.key, this.onRefresh});
  final VoidCallback? onRefresh;
  @override
  Widget build(BuildContext context) =>
      IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh));
}

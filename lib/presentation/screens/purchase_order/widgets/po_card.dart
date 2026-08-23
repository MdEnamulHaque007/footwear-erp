import 'package:flutter/material.dart';
import '../../../../domain/entities/po_entity.dart';

class POCard extends StatelessWidget {
  const POCard({super.key, required this.item});
  final POEntity item;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(item.poNo),
      subtitle: Text('${item.tagNo} | ${item.article}'),
      trailing: Text(item.poValue.toStringAsFixed(2)),
    ),
  );
}

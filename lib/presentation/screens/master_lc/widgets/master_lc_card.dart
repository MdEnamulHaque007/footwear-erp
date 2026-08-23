import 'package:flutter/material.dart';
import '../../../../domain/entities/master_lc_entity.dart';

class MasterLCCard extends StatelessWidget {
  const MasterLCCard({super.key, required this.item});
  final MasterLCEntity item;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(item.tagNo),
      subtitle: Text('${item.company} | ${item.project}'),
      trailing: Text('${item.masterLcQuantity}'),
    ),
  );
}

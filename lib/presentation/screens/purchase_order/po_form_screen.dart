import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/po_entity.dart';
import '../../blocs/purchase_order/po_bloc.dart';
import '../../blocs/purchase_order/po_event.dart';

class POFormScreen extends StatefulWidget {
  const POFormScreen({super.key});
  @override
  State<POFormScreen> createState() => _POFormScreenState();
}

class _POFormScreenState extends State<POFormScreen> {
  final tag = TextEditingController(),
      company = TextEditingController(),
      project = TextEditingController(),
      poNo = TextEditingController(),
      article = TextEditingController(),
      color = TextEditingController(),
      quantity = TextEditingController(),
      price = TextEditingController();
  @override
  void dispose() {
    for (final controller in [
      tag,
      company,
      project,
      poNo,
      article,
      color,
      quantity,
      price,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New Purchase Order')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ...[
          ('Tag No.', tag),
          ('Company', company),
          ('Project', project),
          ('PO No.', poNo),
          ('Article', article),
          ('Color', color),
          ('Quantity', quantity),
          ('Unit Price', price),
        ].map(
          (field) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: field.$2,
              keyboardType: field.$1 == 'Quantity'
                  ? TextInputType.number
                  : TextInputType.text,
              decoration: InputDecoration(labelText: field.$1),
            ),
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: quantity,
          builder: (_, _, _) => ValueListenableBuilder<TextEditingValue>(
            valueListenable: price,
            builder: (_, _, _) => Text(
              'PO Value: ${((int.tryParse(quantity.text) ?? 0) * (double.tryParse(price.text) ?? 0)).toStringAsFixed(2)}',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final item = POEntity(
              sl: DateTime.now().millisecondsSinceEpoch,
              poDate: DateTime.now(),
              tagNo: tag.text.trim(),
              company: company.text.trim(),
              project: project.text.trim(),
              brand: '',
              poNo: poNo.text.trim(),
              article: article.text.trim(),
              color: color.text.trim(),
              poQuantity: int.tryParse(quantity.text) ?? 0,
              unitPrice: double.tryParse(price.text) ?? 0,
              entryPerson: '',
            );
            context.read<POBloc>().add(CreatePO(item));
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

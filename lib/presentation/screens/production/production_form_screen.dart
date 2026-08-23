import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/production_entity.dart';
import '../../blocs/production/production_bloc.dart';
import '../../blocs/production/production_event.dart';

class ProductionFormScreen extends StatefulWidget {
  const ProductionFormScreen({super.key});
  @override
  State<ProductionFormScreen> createState() => _ProductionFormScreenState();
}

class _ProductionFormScreenState extends State<ProductionFormScreen> {
  final voucherNo = TextEditingController(),
      poTag = TextEditingController(),
      quantity = TextEditingController(),
      remarks = TextEditingController();

  @override
  void initState() {
    super.initState();
    final sl = DateTime.now().millisecondsSinceEpoch;
    voucherNo.text =
        '${AppConstants.productionVoucherPrefix}-${sl.toString().substring(sl.toString().length - 6)}';
  }

  @override
  void dispose() {
    for (final controller in [voucherNo, poTag, quantity, remarks]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New Production Record')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ...[
          ('Voucher No.', voucherNo),
          ('PO Tag No.', poTag),
          ('Quantity', quantity),
          ('Remarks', remarks),
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
        ElevatedButton(
          onPressed: () {
            context.read<ProductionBloc>().add(
              CreateProduction(
                ProductionEntity(
                  sl: DateTime.now().millisecondsSinceEpoch,
                  voucherNo: voucherNo.text.trim(),
                  productionDate: DateTime.now(),
                  poTagNo: poTag.text.trim(),
                  quantity: int.tryParse(quantity.text) ?? 0,
                  entryPerson: '',
                  remarks: remarks.text.trim(),
                ),
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/cutting_entity.dart';
import '../../blocs/cutting/cutting_bloc.dart';
import '../../blocs/cutting/cutting_event.dart';

class CuttingFormScreen extends StatefulWidget {
  const CuttingFormScreen({super.key});
  @override
  State<CuttingFormScreen> createState() => _CuttingFormScreenState();
}

class _CuttingFormScreenState extends State<CuttingFormScreen> {
  final voucherNo = TextEditingController(),
      poTag = TextEditingController(),
      quantity = TextEditingController(),
      remarks = TextEditingController();

  @override
  void initState() {
    super.initState();
    final sl = DateTime.now().millisecondsSinceEpoch;
    voucherNo.text =
        '${AppConstants.cuttingVoucherPrefix}-${sl.toString().substring(sl.toString().length - 6)}';
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
    appBar: AppBar(title: const Text('New Cutting Record')),
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
            context.read<CuttingBloc>().add(
              CreateCutting(
                CuttingEntity(
                  sl: DateTime.now().millisecondsSinceEpoch,
                  voucherNo: voucherNo.text.trim(),
                  cuttingDate: DateTime.now(),
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

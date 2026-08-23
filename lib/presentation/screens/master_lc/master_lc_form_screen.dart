import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/master_lc_entity.dart';
import '../../blocs/master_lc/master_lc_bloc.dart';
import '../../blocs/master_lc/master_lc_event.dart';

class MasterLCFormScreen extends StatefulWidget {
  const MasterLCFormScreen({super.key});
  @override
  State<MasterLCFormScreen> createState() => _MasterLCFormScreenState();
}

class _MasterLCFormScreenState extends State<MasterLCFormScreen> {
  final tag = TextEditingController(),
      project = TextEditingController(),
      company = TextEditingController(),
      quantity = TextEditingController(),
      value = TextEditingController();
  @override
  void dispose() {
    tag.dispose();
    project.dispose();
    company.dispose();
    quantity.dispose();
    value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New Master LC')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(
          controller: tag,
          decoration: const InputDecoration(labelText: 'Tag No.'),
        ),
        TextField(
          controller: project,
          decoration: const InputDecoration(labelText: 'Project'),
        ),
        TextField(
          controller: company,
          decoration: const InputDecoration(labelText: 'Company'),
        ),
        TextField(
          controller: quantity,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantity'),
        ),
        TextField(
          controller: value,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'LC Value'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            final item = MasterLCEntity(
              sl: DateTime.now().millisecondsSinceEpoch,
              masterLcDate: DateTime.now(),
              tagNo: tag.text.trim(),
              project: project.text.trim(),
              company: company.text.trim(),
              masterLcQuantity: int.tryParse(quantity.text) ?? 0,
              masterLcValue: double.tryParse(value.text) ?? 0,
            );
            context.read<MasterLCBloc>().add(CreateMasterLC(item));
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

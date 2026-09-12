import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/issue_entity.dart';
import '../../blocs/issue/issue_bloc.dart';
import '../../blocs/issue/issue_event.dart';
import '../../blocs/issue/issue_state.dart';

class IssueFormScreen extends StatefulWidget {
  const IssueFormScreen({super.key});
  @override
  State<IssueFormScreen> createState() => _IssueFormScreenState();
}

class _IssueFormScreenState extends State<IssueFormScreen> {
  final voucherNo = TextEditingController(),
      poTag = TextEditingController(),
      quantity = TextEditingController(),
      remarks = TextEditingController();

  @override
  void initState() {
    super.initState();
    final sl = DateTime.now().millisecondsSinceEpoch;
    voucherNo.text =
        '${AppConstants.issueVoucherPrefix}-${sl.toString().substring(sl.toString().length - 6)}';
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
    appBar: AppBar(title: const Text('New Issue Record')),
    body: BlocConsumer<IssueBloc, IssueState>(
      listener: (context, state) {
        if (state is IssueSuccess) {
          Navigator.pop(context);
        } else if (state is IssueError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) => ListView(
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
            onPressed: state is IssueLoading
                ? null
                : () {
                    context.read<IssueBloc>().add(
                      CreateIssue(
                        IssueEntity(
                          sl: DateTime.now().millisecondsSinceEpoch,
                          voucherNo: voucherNo.text.trim(),
                          issueDate: DateTime.now(),
                          poTagNo: poTag.text.trim(),
                          quantity: int.tryParse(quantity.text) ?? 0,
                          entryPerson: '',
                          remarks: remarks.text.trim(),
                        ),
                      ),
                    );
                  },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

/// ============================================================================
/// ফাইল: lib/presentation/screens/issue/issue_detail_screen.dart
/// স্তর: Presentation Screen | মডিউল: Finished Goods Issue
/// উদ্দেশ্য: Finished Goods Issue মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: IssueDetailScreen, _IssueDetailScreenState
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/issue_entity.dart';
import '../../blocs/issue/issue_bloc.dart';
import '../../blocs/issue/issue_event.dart';
import '../../blocs/issue/issue_state.dart';

/// Issue detail view: issue information, PO information, quantity & value
/// summary, related entries for the same PO line and sync status.
class IssueDetailScreen extends StatefulWidget {
  const IssueDetailScreen({super.key, required this.id, this.initialItem});
  final String id;
  final IssueEntity? initialItem;

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  late final IssueBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.I<IssueBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bloc.add(LoadIssueDetail(widget.id, initialItem: widget.initialItem));
    });
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to Issue List',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/issue'),
        ),
        title: const Text('Issue Details'),
      ),
      body: BlocBuilder<IssueBloc, IssueState>(
        builder: (context, state) {
          if (state is IssueLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is IssueError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _bloc.add(LoadIssueDetail(widget.id)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is! IssueDetailLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = state.item;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('Issue Information', [
                  _row('SL', '${item.sl}'),
                  _row('Issue Date', _date(item.issueDate)),
                  _row('Voucher No', item.voucherNo),
                  _row('Factory', item.factoryName),
                  _row('Entry Person', item.entryPerson),
                ]),
                _section('PO & Master LC Info', [
                  _row('PO No', item.poNo),
                  _row('Tag No', item.effectiveTagNo),
                  _row('Company', item.company),
                  _row('Project', item.project),
                  _row('Article', item.article),
                  _row('Color', item.color),
                ]),
                _section('Quantity & Value Summary', [
                  _row('Production Quantity', '${state.productionQuantity}'),
                  _row('Total Issue Qty', '${state.totalIssueQuantity}'),
                  _row('Available Quantity', '${state.availableQuantity}'),
                  _row('This Issue Qty', '${item.quantity}'),
                  _row(
                    'Remaining After This',
                    '${state.availableQuantity - item.quantity}',
                  ),
                  _row('Unit Price', _money(item.unitPrice)),
                  _row('Issue Value', _money(item.issueValue)),
                ]),
                _section('Sync Status', [
                  _row('Source', item.source ?? 'manual'),
                  _row('Sync Status', item.syncStatus ?? 'synced'),
                  _row('Remarks', item.remarks),
                ]),
                _relatedTable(state),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: item.id == null
                          ? null
                          : () => context.push(
                              '/issue/edit/${item.id}',
                              extra: item,
                            ),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Issue'),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go('/issue'),
                      child: const Text('Back to List'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ),
  );

  Widget _relatedTable(IssueDetailLoaded state) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Related Issue Entries',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('SL')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Voucher')),
            DataColumn(label: Text('Qty')),
            DataColumn(label: Text('Value')),
            DataColumn(label: Text('Entry By')),
          ],
          rows: state.related.asMap().entries.map((entry) {
            final related = entry.value;
            return DataRow(
              cells: [
                DataCell(Text('${entry.key + 1}')),
                DataCell(Text(_date(related.issueDate))),
                DataCell(Text(related.voucherNo)),
                DataCell(Text('${related.quantity}')),
                DataCell(Text(_money(related.issueValue))),
                DataCell(Text(related.entryPerson)),
              ],
            );
          }).toList(),
        ),
      ),
    ],
  );

  Widget _section(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(width: 175, child: Text(label)),
        Expanded(child: Text(value.isEmpty ? '-' : value)),
      ],
    ),
  );

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _money(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

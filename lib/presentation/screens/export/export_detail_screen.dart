import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/export_entity.dart';
import '../../blocs/export/export_bloc.dart';
import '../../blocs/export/export_event.dart';
import '../../blocs/export/export_state.dart';

/// Export detail view: export information, PO information, quantity & value
/// summary, related entries for the same PO line and sync status.
class ExportDetailScreen extends StatefulWidget {
  const ExportDetailScreen({super.key, required this.id, this.initialItem});
  final String id;
  final ExportEntity? initialItem;

  @override
  State<ExportDetailScreen> createState() => _ExportDetailScreenState();
}

class _ExportDetailScreenState extends State<ExportDetailScreen> {
  late final ExportBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.I<ExportBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bloc.add(LoadExportDetail(widget.id, initialItem: widget.initialItem));
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
          tooltip: 'Back to Export List',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/export'),
        ),
        title: const Text('Export Details'),
      ),
      body: BlocBuilder<ExportBloc, ExportState>(
        builder: (context, state) {
          if (state is ExportLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExportError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _bloc.add(LoadExportDetail(widget.id)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is! ExportDetailLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = state.item;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('Export Information', [
                  _row('SL', '${item.sl}'),
                  _row('Export Date', _date(item.exportDate)),
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
                  _row('Issue Quantity', '${state.issueQuantity}'),
                  _row('Total Export Qty', '${state.totalExportQuantity}'),
                  _row('Available Quantity', '${state.availableQuantity}'),
                  _row('This Export Qty', '${item.quantity}'),
                  _row(
                    'Remaining After This',
                    '${state.availableQuantity - item.quantity}',
                  ),
                  _row('Unit Price', _money(item.unitPrice)),
                  _row('Export Value', _money(item.exportValue)),
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
                              '/export/edit/${item.id}',
                              extra: item,
                            ),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Export'),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go('/export'),
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

  Widget _relatedTable(ExportDetailLoaded state) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Related Export Entries',
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
                DataCell(Text(_date(related.exportDate))),
                DataCell(Text(related.voucherNo)),
                DataCell(Text('${related.quantity}')),
                DataCell(Text(_money(related.exportValue))),
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

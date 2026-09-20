import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/sewing_entity.dart';
import '../../blocs/sewing/sewing_bloc.dart';
import '../../blocs/sewing/sewing_event.dart';
import '../../blocs/sewing/sewing_state.dart';

/// Sewing detail view, mirroring the Cutting layout: Sewing information, PO
/// information, quantity summary, related Sewing entries and sync status.
///
/// The record is loaded through [SewingBloc] (registered as a factory in DI) so
/// the screen stays consistent with the rest of the module.
class SewingDetailScreen extends StatefulWidget {
  const SewingDetailScreen({super.key, required this.id, this.initialItem});
  final String id;
  final SewingEntity? initialItem;

  @override
  State<SewingDetailScreen> createState() => _SewingDetailScreenState();
}

class _SewingDetailScreenState extends State<SewingDetailScreen> {
  late final SewingBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.I<SewingBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bloc.add(
        LoadSewingDetail(widget.id, initialItem: widget.initialItem),
      );
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
          tooltip: 'Back to Sewing List',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/sewing'),
        ),
        title: const Text('Sewing Details'),
      ),
      body: BlocBuilder<SewingBloc, SewingState>(
        builder: (context, state) {
          if (state is SewingLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SewingError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _bloc.add(
                        LoadSewingDetail(widget.id),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is! SewingDetailLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = state.item;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('Sewing Information', [
                  _row('SL', '${item.sl}'),
                  _row('Sewing Date', _date(item.sewingDate)),
                  _row('Voucher No', item.voucherNo),
                  _row('Factory', item.factoryName),
                  _row('Entry Person', item.entryPerson),
                ]),
                _section('PO & Master LC Info', [
                  _row('PO No', item.poNo),
                  _row(
                    'Tag No',
                    item.tagNo,
                  ),
                  _row('Company', item.company),
                  _row('Project', item.project),
                  _row('Article', item.article),
                  _row('Color', item.color),
                ]),
                _section('Quantity Summary', [
                  _row('Cutting Quantity', '${state.cuttingQuantity}'),
                  _row('Total Sewing Qty', '${state.totalSewingQuantity}'),
                  _row('Available Quantity', '${state.availableQuantity}'),
                  _row('This Sewing Qty', '${item.sewingQuantity}'),
                  _row(
                    'Remaining After This',
                    '${state.availableQuantity - item.effectiveQuantity}',
                  ),
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
                              '/sewing/edit/${item.id}',
                              extra: item,
                            ),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Sewing'),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go('/sewing'),
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

  Widget _relatedTable(SewingDetailLoaded state) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Related Sewing Entries',
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
            DataColumn(label: Text('Entry By')),
          ],
          rows: state.related.asMap().entries.map((entry) {
            final related = entry.value;
            return DataRow(
              cells: [
                DataCell(Text('${entry.key + 1}')),
                DataCell(Text(_date(related.sewingDate))),
                DataCell(Text(related.voucherNo)),
                DataCell(Text('${related.sewingQuantity}')),
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
        SizedBox(width: 160, child: Text(label)),
        Expanded(child: Text(value.isEmpty ? '-' : value)),
      ],
    ),
  );

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}


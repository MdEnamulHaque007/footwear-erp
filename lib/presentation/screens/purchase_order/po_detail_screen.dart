import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/master_lc_entity.dart';
import '../../../domain/entities/po_entity.dart';
import '../../blocs/purchase_order/po_bloc.dart';
import '../../blocs/purchase_order/po_event.dart';
import '../../blocs/purchase_order/po_state.dart';

class PODetailScreen extends StatefulWidget {
  const PODetailScreen({super.key, required this.id, this.initialItem});
  final String id;
  final POEntity? initialItem;

  @override
  State<PODetailScreen> createState() => _PODetailScreenState();
}

class _PODetailScreenState extends State<PODetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<POBloc>().add(
            LoadPODetail(widget.id, initialItem: widget.initialItem),
          );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.initialItem == null
              ? 'Purchase Order Details'
              : '${widget.initialItem!.poNo} Details'),
          actions: [
            if (widget.initialItem != null)
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit),
                onPressed: () => context.push(
                  '/purchase-orders/edit/${widget.id}',
                  extra: widget.initialItem,
                ),
              ),
          ],
        ),
        body: BlocBuilder<POBloc, POState>(
          builder: (context, state) {
            if (state is PODetailLoading || state is POInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PODetailError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.read<POBloc>().add(
                            LoadPODetail(widget.id, initialItem: widget.initialItem),
                          ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (state is! PODetailLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            return _DetailBody(
              item: state.item,
              master: state.master,
              totalTagQuantity: state.totalTagQuantity ?? state.item.totalQuantity,
              totalTagValue: state.totalTagValue ?? state.item.totalValue,
            );
          },
        ),
      );
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.item,
    required this.master,
    required this.totalTagQuantity,
    required this.totalTagValue,
  });
  final POEntity item;
  final MasterLCEntity master;
  final int totalTagQuantity;
  final double totalTagValue;

  @override
  Widget build(BuildContext context) {
    final items = item.effectiveLineItems;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _sectionTitle('PO Information'),
        _infoGrid([
          _info('PO Date', DateFormat('dd/MM/yyyy').format(item.poDate)),
          _info('PO No', item.poNo),
          _info('Entry Person', item.entryPerson),
          _info('Brand', item.brand),
          _info('Created At', _dateTime(item.createdAt)),
          _info('Updated At', _dateTime(item.updatedAt)),
        ]),
        const SizedBox(height: 24),
        _sectionTitle('Master LC Information'),
        _infoGrid([
          _info('Tag No', master.tagNo),
          _info('Company', master.company),
          _info('Project', master.project),
          _info('Master LC No', master.lcNo),
          _info('Master LC Quantity', '${master.masterLcQuantity}'),
          _info('Master LC Value', _money(master.masterLcValue)),
          _info('Available Quantity',
              '${master.masterLcQuantity - totalTagQuantity}'),
          _info('Available Value',
              _money(master.masterLcValue - totalTagValue)),
        ]),
        const SizedBox(height: 24),
        _sectionTitle('Line Items'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            border: TableBorder.all(color: Colors.grey.shade300),
            headingRowColor:
                WidgetStateProperty.all(Colors.blueGrey.shade50),
            columns: const [
              DataColumn(label: Text('SL')),
              DataColumn(label: Text('Article')),
              DataColumn(label: Text('Color')),
              DataColumn(label: Text('Quantity')),
              DataColumn(label: Text('Unit Price')),
              DataColumn(label: Text('PO Value')),
            ],
            rows: items.asMap().entries.map((entry) {
              final line = entry.value;
              return DataRow(cells: [
                DataCell(Text('${entry.key + 1}')),
                DataCell(Text(line.article)),
                DataCell(Text(line.color)),
                DataCell(Text('${line.poQuantity}')),
                DataCell(Text(_money(line.unitPrice))),
                DataCell(Text(_money(line.poValue))),
              ]);
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Summary'),
        _infoGrid([
          _info('Total Line Items', '${items.length}'),
          _info('Total Quantity', '${item.totalQuantity}'),
          _info('Total Value', _money(item.totalValue)),
        ]),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
            FilledButton.icon(
              onPressed: item.id == null
                  ? null
                  : () => context.push(
                        '/purchase-orders/edit/${item.id}',
                        extra: item,
                      ),
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _infoGrid(List<Widget> children) => Wrap(
        spacing: 16,
        runSpacing: 12,
        children: children,
      );

  Widget _info(String label, String value) => SizedBox(
        width: 220,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          child: Text(value.isEmpty ? '-' : value),
        ),
      );

  String _money(num value) => NumberFormat('#,##0.00').format(value);
  String _dateTime(DateTime? value) =>
      value == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(value);
}

/// ============================================================================
/// ফাইল: lib/presentation/screens/master_lc/master_lc_detail_screen.dart
/// স্তর: Presentation Screen | মডিউল: Master LC
/// উদ্দেশ্য: Master LC মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: MasterLCDetailScreen, _MasterLCDetailScreenState
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/master_lc_entity.dart';
import '../../../domain/entities/po_entity.dart';
import '../../blocs/master_lc/master_lc_bloc.dart';
import '../../blocs/master_lc/master_lc_event.dart';
import '../../blocs/master_lc/master_lc_state.dart';
import '../../blocs/purchase_order/po_bloc.dart';
import '../../blocs/purchase_order/po_event.dart';
import '../../blocs/purchase_order/po_state.dart';

class MasterLCDetailScreen extends StatefulWidget {
  const MasterLCDetailScreen({
    super.key,
    required this.id,
    this.initialItem,
  });
  final String id;
  final MasterLCEntity? initialItem;

  @override
  State<MasterLCDetailScreen> createState() => _MasterLCDetailScreenState();
}

class _MasterLCDetailScreenState extends State<MasterLCDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MasterLCBloc>().add(
            LoadMasterLCDetail(widget.id, initialItem: widget.initialItem),
          );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Master LC Details')),
        body: BlocListener<MasterLCBloc, MasterLCState>(
          listener: (context, state) {
            if (state is MasterLCDetailLoaded) {
              context.read<POBloc>().add(LoadPOByTag(state.masterLC.tagNo));
            }
          },
          child: BlocBuilder<MasterLCBloc, MasterLCState>(
            builder: (context, masterState) {
              if (masterState is MasterLCDetailLoading ||
                  masterState is MasterLCInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (masterState is MasterLCDetailError) {
                return Center(child: Text(masterState.message));
              }
              if (masterState is! MasterLCDetailLoaded) {
                return const SizedBox.shrink();
              }
              return BlocBuilder<POBloc, POState>(
                builder: (context, poState) {
                  if (poState is POLoading || poState is POInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final orders =
                      poState is POLoaded ? poState.items : <POEntity>[];
                  return _body(context, masterState.masterLC, orders);
                },
              );
            },
          ),
        ),
      );

  Widget _body(
    BuildContext context,
    MasterLCEntity master,
    List<POEntity> orders,
  ) {
    final totalQty =
        orders.fold<int>(0, (sum, item) => sum + item.totalQuantity);
    final totalValue =
        orders.fold<double>(0, (sum, item) => sum + item.totalValue);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _title('Basic Information'),
        _grid([
          _info('SL', '${master.sl}'),
          _info('Master LC Date', _date(master.masterLcDate)),
          _info('Tag No', master.tagNo),
          _info('Project', master.project),
          _info('Company', master.company),
          _info('SC No', master.scNo),
          _info('LC No', master.lcNo),
          _info('TT No', master.ttNo),
          _info('Master LC Quantity', _quantity(master.masterLcQuantity)),
          _info('Master LC Value', _value(master.masterLcValue)),
        ]),
        const SizedBox(height: 24),
        _title('Purchase Orders'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            border: TableBorder.all(color: Colors.grey.shade300),
            columns: const [
              DataColumn(label: Text('SL')),
              DataColumn(label: Text('PO No')),
              DataColumn(label: Text('PO Date')),
              DataColumn(label: Text('Total Qty')),
              DataColumn(label: Text('Total Value')),
            ],
            rows: orders.asMap().entries.map((entry) {
              final item = entry.value;
              return DataRow(cells: [
                DataCell(Text('${entry.key + 1}')),
                DataCell(Text(item.poNo)),
                DataCell(Text(_date(item.poDate))),
                DataCell(Text(_quantity(item.totalQuantity))),
                DataCell(Text(_value(item.totalValue))),
              ]);
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        _title('Summary'),
        _grid([
          _info('Master LC Quantity', _quantity(master.masterLcQuantity)),
          _info('Total PO Quantity', _quantity(totalQty)),
          _info('Pending Quantity',
              _quantity(master.masterLcQuantity - totalQty)),
          _info('Master LC Value', _value(master.masterLcValue)),
          _info('Total PO Value', _value(totalValue)),
          _info('Pending Value', _value(master.masterLcValue - totalValue)),
        ]),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => context.push(
                '/master-lc/edit/${master.id}',
                extra: master,
              ),
              icon: const Icon(Icons.edit),
              label: const Text('Edit LC'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push(
                '/purchase-orders/new?tag=${Uri.encodeComponent(master.tagNo)}',
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add PO'),
            ),
            TextButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _grid(List<Widget> children) =>
      Wrap(spacing: 16, runSpacing: 12, children: children);

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

  String _date(DateTime value) => DateFormat('dd/MM/yyyy').format(value);
  String _quantity(int value) => NumberFormat('#,##0').format(value);
  String _value(double value) =>
      NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value);
}

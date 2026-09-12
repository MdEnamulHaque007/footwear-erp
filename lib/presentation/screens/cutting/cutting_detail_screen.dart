import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/cutting_entity.dart';
import '../../../domain/repositories/i_cutting_repository.dart';

class CuttingDetailScreen extends StatefulWidget {
  const CuttingDetailScreen({super.key, required this.id, this.initialItem});
  final String id;
  final CuttingEntity? initialItem;

  @override
  State<CuttingDetailScreen> createState() => _CuttingDetailScreenState();
}

class _CuttingDetailScreenState extends State<CuttingDetailScreen> {
  late Future<_DetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DetailData> _load() async {
    final repository = GetIt.I<ICuttingRepository>();
    final itemResult = await repository.byId(widget.id);
    return itemResult.fold((error) => throw Exception(error), (item) async {
      final selected = item ?? widget.initialItem;
      if (selected == null) throw Exception('Cutting record not found');
      final related = await repository.byLine(
        poNo: selected.poNo,
        article: selected.article,
        color: selected.color,
      );
      return related.fold(
        (error) => throw Exception(error),
        (entries) => _DetailData(selected, entries),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back to Cutting List',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/cutting'),
      ),
      title: const Text('Cutting Details'),
    ),
    body: FutureBuilder<_DetailData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Unable to load cutting details. Please try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => setState(() => _future = _load()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data!;
        final total = data.related.fold<int>(
          0,
          (sum, entry) => sum + entry.cuttingQuantity,
        );
        final available = data.item.poQuantity - total;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section('Cutting Information', [
                _row('SL', '${data.item.sl}'),
                _row('Date', _date(data.item.cuttingDate)),
                _row('Voucher No', data.item.voucherNo),
                _row('Factory', data.item.factoryName),
                _row('Entry Person', data.item.entryPerson),
              ]),
              _section('PO Information', [
                _row('PO No', data.item.poNo),
                _row('Tag No', data.item.tagNo),
                _row('Company', data.item.company),
                _row('Project', data.item.project),
                _row('Article', data.item.article),
                _row('Color', data.item.color),
              ]),
              _section('Quantity Summary', [
                _row('PO Quantity', '${data.item.poQuantity}'),
                _row('This Cutting Qty', '${data.item.cuttingQuantity}'),
                _row('Total Cutting Qty', '$total'),
                _row('Available Quantity', '$available'),
                _row(
                  'Remaining After This',
                  '${available - data.item.cuttingQuantity}',
                ),
              ]),
              const SizedBox(height: 16),
              const Text(
                'Related Cutting Entries',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('SL')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Voucher')),
                    DataColumn(label: Text('Qty')),
                    DataColumn(label: Text('By')),
                  ],
                  rows: data.related.asMap().entries.map((entry) {
                    final item = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(Text('${entry.key + 1}')),
                        DataCell(Text(_date(item.cuttingDate))),
                        DataCell(Text(item.voucherNo)),
                        DataCell(Text('${item.cuttingQuantity}')),
                        DataCell(Text(item.entryPerson)),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.push(
                      '/cutting/edit/${data.item.id}',
                      extra: data.item,
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Cutting'),
                  ),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back to List'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
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
        SizedBox(width: 150, child: Text(label)),
        Expanded(child: Text(value.isEmpty ? '-' : value)),
      ],
    ),
  );

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _DetailData {
  const _DetailData(this.item, this.related);
  final CuttingEntity item;
  final List<CuttingEntity> related;
}

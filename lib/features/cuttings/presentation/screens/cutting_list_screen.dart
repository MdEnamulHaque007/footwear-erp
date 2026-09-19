import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/cutting_model.dart';
import 'providers/cutting_provider.dart';

class CuttingListScreen extends ConsumerStatefulWidget {
  const CuttingListScreen({super.key});

  @override
  ConsumerState<CuttingListScreen> createState() => _CuttingListScreenState();
}

class _CuttingListScreenState extends ConsumerState<CuttingListScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncCuttings = ref.watch(cuttingsListProvider);
    final filters = ref.watch(cuttingFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cutting / কাটিং'),
        actions: [
          IconButton(
            tooltip: 'Date filter',
            onPressed: () => _pickDateRange(filters),
            icon: const Icon(Icons.date_range),
          ),
          if (filters.from != null || filters.to != null)
            IconButton(
              tooltip: 'Clear date filter',
              onPressed: () {
                ref.read(cuttingFiltersProvider.notifier).state =
                    filters.copyWith(clearFrom: true, clearTo: true);
              },
              icon: const Icon(Icons.filter_alt_off),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search PO No / Article / V.No',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  setState(() => _search = value.trim().toLowerCase()),
            ),
          ),
          if (filters.from != null || filters.to != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filters.from == null ? '' : DateFormat('dd-MMM-yyyy').format(filters.from!)}'
                  ' → '
                  '${filters.to == null ? '' : DateFormat('dd-MMM-yyyy').format(filters.to!)}',
                ),
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(cuttingsListProvider),
              child: asyncCuttings.when(
                loading: () => const _CuttingShimmer(),
                error: (error, _) => ListView(
                  children: [
                    const SizedBox(height: 120),
                    Center(child: Text('Failed to load cuttings\n$error')),
                  ],
                ),
                data: (items) {
                  final filtered = items.where((item) {
                    if (_search.isEmpty) return true;
                    return item.poNo.toLowerCase().contains(_search) ||
                        item.article.toLowerCase().contains(_search) ||
                        item.voucherNo.toLowerCase().contains(_search);
                  }).toList();

                  if (filtered.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 140),
                        Center(
                          child: Text(
                            'No cutting records found / কোনো রেকর্ড নেই',
                          ),
                        ),
                      ],
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('V.No')),
                              DataColumn(label: Text('PO No')),
                              DataColumn(label: Text('Article')),
                              DataColumn(label: Text('Color')),
                              DataColumn(label: Text('Qty')),
                              DataColumn(label: Text('Factory')),
                            ],
                            rows: filtered.map(_row).toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/cuttings/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Cutting'),
      ),
    );
  }

  DataRow _row(Cutting item) {
    return DataRow(
      onSelectChanged: (_) => context.push('/cuttings/${_docId(item)}'),
      cells: [
        DataCell(Text(item.formattedDate)),
        DataCell(Text(item.voucherNo)),
        DataCell(Text(item.poNo)),
        DataCell(Text(item.article)),
        DataCell(Text(item.color)),
        DataCell(Text(item.cuttingQuantity.toString())),
        DataCell(Text(item.factoryName)),
      ],
    );
  }

  String _docId(Cutting item) {
    String sanitize(String value) =>
        value.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-');
    return '${DateFormat('yyyyMMdd').format(item.cuttingDate)}_'
        '${sanitize(item.poNo)}_${sanitize(item.article)}_${sanitize(item.color)}';
  }

  Future<void> _pickDateRange(CuttingFilters filters) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: filters.from == null && filters.to == null
          ? null
          : DateTimeRange(
              start: filters.from ?? filters.to!,
              end: filters.to ?? filters.from!,
            ),
    );
    if (range == null) return;

    ref.read(cuttingFiltersProvider.notifier).state = CuttingFilters(
      poNo: filters.poNo,
      from: DateTime(range.start.year, range.start.month, range.start.day),
      to: DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
        999,
      ),
    );
  }
}

class _CuttingShimmer extends StatefulWidget {
  const _CuttingShimmer();

  @override
  State<_CuttingShimmer> createState() => _CuttingShimmerState();
}

class _CuttingShimmerState extends State<_CuttingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => ListView.builder(
        itemCount: 8,
        itemBuilder: (_, index) => Opacity(
          opacity: 0.35 + (_controller.value * 0.4),
          child: Container(
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

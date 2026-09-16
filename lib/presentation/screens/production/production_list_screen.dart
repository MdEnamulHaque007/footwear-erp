import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/production_entity.dart';
import '../../blocs/production/production_bloc.dart';
import '../../blocs/production/production_event.dart';
import '../../blocs/production/production_state.dart';
import '../../widgets/excel_column_filter_header.dart';

/// Excel-style Production list: serial number, horizontal + vertical scroll and
/// double-click to open the detail view.
class ProductionListScreen extends StatefulWidget {
  const ProductionListScreen({super.key});

  @override
  State<ProductionListScreen> createState() => _ProductionListScreenState();
}

class _ProductionListScreenState extends State<ProductionListScreen> {
  final verticalScroll = ScrollController();
  final horizontalScroll = ScrollController();
  String query = '';
  final Map<String, String> _columnFilters = {};

  void _setColumnFilter(String key, String value) {
    setState(() {
      if (value.isEmpty) {
        _columnFilters.remove(key);
      } else {
        _columnFilters[key] = value;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductionBloc>().add(LoadProductionList());
    });
    verticalScroll.addListener(() {
      if (verticalScroll.position.pixels >=
          verticalScroll.position.maxScrollExtent - 200) {
        context.read<ProductionBloc>().add(LoadMoreProductionList());
      }
    });
  }

  @override
  void dispose() {
    verticalScroll.dispose();
    horizontalScroll.dispose();
    super.dispose();
  }

  bool _matches(ProductionEntity item) {
    final value = query.toLowerCase();
    final matchesSearch = value.isEmpty ||
        item.poNo.toLowerCase().contains(value) ||
        item.voucherNo.toLowerCase().contains(value) ||
        item.poTagNo.toLowerCase().contains(value) ||
        item.article.toLowerCase().contains(value) ||
        item.color.toLowerCase().contains(value);
    return matchesSearch &&
        ExcelColumnFilterHeader.matches(_columnFilters, {
          'sl': item.sl,
          'date': _date(item.productionDate),
          'voucher': item.voucherNo,
          'factory': item.factoryName,
          'po': item.poNo,
          'tag': item.effectiveTagNo,
          'article': item.article,
          'color': item.color,
          'quantity': item.quantity,
          'value': _money(item.productionValue),
          'entry': item.entryPerson,
        });
  }

  Future<void> _delete(ProductionEntity item) async {
    final id = item.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete production record?'),
        content: Text('${item.voucherNo} will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<ProductionBloc>().add(DeleteProduction(id));
    }
  }

  void _openDetail(ProductionEntity item) =>
      context.push('/production/detail/${item.id}', extra: item);

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _money(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back to Dashboard',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/dashboard'),
      ),
      title: const Text('Production'),
      actions: [
        _totalQuantityBadge(),
        IconButton(
          tooltip: 'Search',
          icon: const Icon(Icons.search),
          onPressed: () async {
            final bloc = context.read<ProductionBloc>();
            final value = await showSearch<String?>(
              context: context,
              delegate: _ProductionSearchDelegate(query),
            );
            if (value != null && mounted) {
              setState(() => query = value);
              bloc.add(SearchProduction(value));
            }
          },
        ),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<ProductionBloc>().add(RefreshProduction()),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.push('/production/new'),
      child: const Icon(Icons.add),
    ),
    body: BlocConsumer<ProductionBloc, ProductionState>(
      listener: (context, state) {
        if (state is ProductionSuccess || state is ProductionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state is ProductionSuccess
                    ? state.message
                    : (state as ProductionError).message,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ProductionLoading && state is! ProductionLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = state is ProductionLoaded
            ? state.items.where(_matches).toList()
            : <ProductionEntity>[];
        if (items.isEmpty) {
          return const Center(child: Text('No Production Records'));
        }
        return _table(items);
      },
    ),
  );

  Widget _totalQuantityBadge() => BlocBuilder<ProductionBloc, ProductionState>(
    buildWhen: (_, state) => state is ProductionLoaded,
    builder: (context, state) {
      final total = state is ProductionLoaded
          ? state.items
                .where(_matches)
                .fold<int>(0, (sum, item) => sum + item.quantity)
          : 0;
      return _totalBadge(total);
    },
  );

  Widget _totalBadge(int total) => Padding(
    padding: const EdgeInsets.only(right: 4),
    child: Center(
      child: Tooltip(
        message: 'Total quantity in the current filtered list',
        child: Text(
          'Total Qty\n$total',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    ),
  );

  Widget _table(List<ProductionEntity> items) => Scrollbar(
    controller: horizontalScroll,
    thumbVisibility: true,
    notificationPredicate: (notification) => notification.depth == 1,
    child: SingleChildScrollView(
      controller: verticalScroll,
      padding: const EdgeInsets.all(12),
      child: Scrollbar(
        controller: verticalScroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: horizontalScroll,
          scrollDirection: Axis.horizontal,
          child: DataTable(
              columnSpacing: 14,
              headingRowColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              columns: [
                _filterColumn('SL', 'sl'),
                _filterColumn('Production Date', 'date'),
                _filterColumn('Voucher', 'voucher'),
                _filterColumn('Factory', 'factory'),
                _filterColumn('PO No', 'po'),
                _filterColumn('Tag No', 'tag'),
                _filterColumn('Article', 'article'),
                _filterColumn('Color', 'color'),
                _filterColumn('Qty', 'quantity'),
                _filterColumn('Value', 'value'),
                _filterColumn('Entry By', 'entry'),
                DataColumn(label: Text('Action')),
              ],
              rows: items.asMap().entries.map((entry) {
                final item = entry.value;
                final id = item.id;
                return DataRow(
                  onSelectChanged: id == null ? null : (_) => _openDetail(item),
                  cells: [
                    DataCell(
                      GestureDetector(
                        onDoubleTap: id == null ? null : () => _openDetail(item),
                        child: Text('${entry.key + 1}'),
                      ),
                    ),
                    DataCell(Text(_date(item.productionDate))),
                    DataCell(Text(item.voucherNo)),
                    DataCell(Text(item.factoryName)),
                    DataCell(Text(item.poNo)),
                    DataCell(Text(item.effectiveTagNo)),
                    DataCell(Text(item.article)),
                    DataCell(Text(item.color)),
                    DataCell(Text('${item.quantity}')),
                    DataCell(Text(_money(item.productionValue))),
                    DataCell(Text(item.entryPerson)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            color: Colors.blue,
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: id == null
                                ? null
                                : () => context.push(
                                    '/production/edit/$id',
                                    extra: item,
                                  ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            color: Colors.red,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: id == null ? null : () => _delete(item),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
          ),
        ),
      ),
    ),
  );

  DataColumn _filterColumn(String label, String key) {
    return DataColumn(
      label: ExcelColumnFilterHeader(
        label: label,
        value: _columnFilters[key] ?? '',
        onChanged: (value) => _setColumnFilter(key, value),
      ),
    );
  }
}

class _ProductionSearchDelegate extends SearchDelegate<String?> {
  _ProductionSearchDelegate(String initial) {
    query = initial;
  }
  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
  ];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back),
  );
  @override
  Widget buildResults(BuildContext context) => ListTile(
    title: Text(query),
    trailing: const Icon(Icons.check),
    onTap: () => close(context, query),
  );
  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}

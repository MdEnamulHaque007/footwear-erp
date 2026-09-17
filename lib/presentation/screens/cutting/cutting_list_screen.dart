import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/cutting_entity.dart';
import '../../blocs/cutting/cutting_bloc.dart';
import '../../blocs/cutting/cutting_event.dart';
import '../../blocs/cutting/cutting_state.dart';
import '../../widgets/excel_column_filter_header.dart';

class CuttingListScreen extends StatefulWidget {
  const CuttingListScreen({super.key});
  @override
  State<CuttingListScreen> createState() => _CuttingListScreenState();
}

class _CuttingListScreenState extends State<CuttingListScreen> {
  final verticalScroll = ScrollController();
  final horizontalScroll = ScrollController();
  String query = '';
  final Map<String, String> _columnFilters = {};
  int _pageSize = 20;
  int _currentPage = 0;

  void _setColumnFilter(String key, String value) {
    setState(() {
      if (value.isEmpty) {
        _columnFilters.remove(key);
      } else {
        _columnFilters[key] = value;
      }
      _currentPage = 0;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CuttingBloc>().add(const LoadCuttingList(limit: 1000));
    });
  }

  @override
  void dispose() {
    verticalScroll.dispose();
    horizontalScroll.dispose();
    super.dispose();
  }

  bool _matches(CuttingEntity item) {
    final value = query.toLowerCase();
    final matchesSearch = item.poNo.toLowerCase().contains(value) ||
        item.voucherNo.toLowerCase().contains(value) ||
        item.tagNo.toLowerCase().contains(value) ||
        item.poTagNo.toLowerCase().contains(value);
    return matchesSearch &&
        ExcelColumnFilterHeader.matches(_columnFilters, {
          'date': '${item.cuttingDate.day.toString().padLeft(2, '0')}/${item.cuttingDate.month.toString().padLeft(2, '0')}/${item.cuttingDate.year}',
          'voucher': item.voucherNo,
          'factory': item.factoryName,
          'project': item.project,
          'po': item.poNo,
          'article': item.article,
          'color': item.color,
          'quantity': item.cuttingQuantity,
          'entry': item.entryPerson,
        });
  }

  void _openDetail(CuttingEntity item) {
    if (item.id == null) return;
    context.push('/cutting/detail/${item.id}', extra: item);
  }

  void _openEdit(CuttingEntity item) {
    if (item.id == null) return;
    context.push('/cutting/edit/${item.id}', extra: item);
  }

  /// Confirms and dispatches the delete for [item].
  ///
  /// `dialogContext` is used for the pop so the dialog is dismissed from inside
  /// its own builder instead of the list's context (context shadow fix).
  Future<void> _delete(CuttingEntity item) async {
    final id = item.id;
    if (id == null) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this Cutting record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CuttingBloc>().add(DeleteCutting(id));
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back to Dashboard',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/dashboard'),
      ),
      title: const Text('Cutting'),
      actions: [
        _totalQuantityBadge(),
        IconButton(
          tooltip: 'Search',
          icon: const Icon(Icons.search),
          onPressed: () async {
            final value = await showSearch<String?>(
              context: context,
              delegate: _CuttingSearchDelegate(query),
            );
            if (value != null && mounted) {
              setState(() {
                query = value;
                _currentPage = 0;
              });
            }
          },
        ),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<CuttingBloc>().add(
            const RefreshCutting(limit: 1000),
          ),
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _pageSize,
            items: const [20, 50, 100]
                .map(
                  (size) => DropdownMenuItem(
                    value: size,
                    child: Text('$size rows'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _pageSize = value;
                _currentPage = 0;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.push('/cutting/new'),
      child: const Icon(Icons.add),
    ),
    body: BlocConsumer<CuttingBloc, CuttingState>(
      listener: (context, state) {
        if (state is CuttingSuccess || state is CuttingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state is CuttingSuccess
                    ? state.message
                    : (state as CuttingError).message,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is CuttingLoading && state is! CuttingLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = state is CuttingLoaded
            ? state.items.where(_matches).toList()
            : <CuttingEntity>[];
        if (items.isEmpty) {
          return const Center(child: Text('No Cutting Records'));
        }
        final totalPages = (items.length / _pageSize).ceil();
        final page = _currentPage.clamp(0, totalPages - 1);
        final pageItems = items
            .skip(page * _pageSize)
            .take(_pageSize)
            .toList();
        return Column(
          children: [
            Expanded(
              child: Scrollbar(
                controller: verticalScroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: verticalScroll,
                  padding: const EdgeInsets.all(12),
                  child: Scrollbar(
                    controller: horizontalScroll,
                    thumbVisibility: true,
                    notificationPredicate: (notification) =>
                        notification.depth == 1,
                    child: SingleChildScrollView(
                      controller: horizontalScroll,
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                    columnSpacing: 14,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 50,
                    headingRowColor: WidgetStatePropertyAll(
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    columns: [
                      _filterColumn('Cutting Date', 'date'),
                      _filterColumn('Voucher No', 'voucher'),
                      _filterColumn('Factory', 'factory'),
                      _filterColumn('Project', 'project'),
                      _filterColumn('PO No', 'po'),
                      _filterColumn('Article', 'article'),
                      _filterColumn('Color', 'color'),
                      _filterColumn('Cutting Qty', 'quantity'),
                      _filterColumn('Entry Person', 'entry'),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: pageItems
                        .asMap()
                        .entries
                        .map(
                          (entry) => DataRow(
                            color: WidgetStatePropertyAll(
                              entry.key.isEven ? Colors.grey.shade50 : null,
                            ),
                            onSelectChanged: entry.value.id == null
                                ? null
                                : (_) => _openDetail(entry.value),
                            cells: [
                              DataCell(
                                _cell(
                                  '${entry.value.cuttingDate.day.toString().padLeft(2, '0')}/${entry.value.cuttingDate.month.toString().padLeft(2, '0')}/${entry.value.cuttingDate.year}',
                                ),
                              ),
                              DataCell(_cell(entry.value.voucherNo)),
                              DataCell(_cell(entry.value.factoryName)),
                              DataCell(_cell(entry.value.project)),
                              DataCell(_cell(entry.value.poNo)),
                              DataCell(_cell(entry.value.article)),
                              DataCell(_cell(entry.value.color)),
                              DataCell(
                                _cell(entry.value.cuttingQuantity.toString()),
                              ),
                              DataCell(_cell(entry.value.entryPerson)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit Cutting',
                                      iconSize: 20,
                                      color: Colors.blue,
                                      icon: const Icon(Icons.edit),
                                      onPressed: entry.value.id == null
                                          ? null
                                          : () => _openEdit(entry.value),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete Cutting',
                                      iconSize: 20,
                                      color: Colors.red,
                                      icon: const Icon(Icons.delete),
                                      onPressed: entry.value.id == null
                                          ? null
                                          : () => _delete(entry.value),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: page == 0
                      ? null
                      : () => setState(() => _currentPage = page - 1),
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Previous'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Page ${page + 1} of $totalPages'),
                ),
                FilledButton.icon(
                  onPressed: page >= totalPages - 1
                      ? null
                      : () => setState(() => _currentPage = page + 1),
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Next'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    ),
  );

  Widget _totalQuantityBadge() => BlocBuilder<CuttingBloc, CuttingState>(
    buildWhen: (_, state) => state is CuttingLoaded,
    builder: (context, state) {
      final total = state is CuttingLoaded
          ? state.items
                .where(_matches)
                .fold<int>(0, (sum, item) => sum + item.cuttingQuantity)
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

  Widget _cell(String value) => Text(value, style: const TextStyle(fontSize: 12));

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

class _CuttingSearchDelegate extends SearchDelegate<String?> {
  _CuttingSearchDelegate(String initial) {
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

/// ============================================================================
/// ফাইল: lib/presentation/screens/purchase_order/po_list_screen.dart
/// স্তর: Presentation Screen | মডিউল: Purchase Order
/// উদ্দেশ্য: Purchase Order মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: POListScreen, _POListScreenState, _PODataTable
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/po_entity.dart';
import '../../blocs/purchase_order/po_bloc.dart';
import '../../blocs/purchase_order/po_event.dart';
import '../../blocs/purchase_order/po_state.dart';
import '../../widgets/excel_column_filter_header.dart';

class POListScreen extends StatefulWidget {
  const POListScreen({super.key});

  @override
  State<POListScreen> createState() => _POListScreenState();
}

class _POListScreenState extends State<POListScreen> {
  final _vertical = ScrollController();
  final _horizontal = ScrollController();
  final _searchController = TextEditingController();
  bool _searching = false;
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

  bool _matchesColumnFilters(POEntity item) {
    return ExcelColumnFilterHeader.matches(_columnFilters, {
      'sl': item.sl,
      'date': DateFormat('dd/MM/yyyy').format(item.poDate),
      'po': item.poNo,
      'quantity': item.totalQuantity,
      'value': item.totalValue.toStringAsFixed(2),
      'entry': item.entryPerson,
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<POBloc>().add(LoadPOList());
    });
    _vertical.addListener(() {
      if (_vertical.position.pixels >=
              _vertical.position.maxScrollExtent - 200 &&
          context.read<POBloc>().state is POLoaded) {
        context.read<POBloc>().add(LoadMorePOList());
      }
    });
  }

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/'),
      ),
      title: _searching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search PO, tag, company or project',
                border: InputBorder.none,
              ),
              onChanged: (query) =>
                  context.read<POBloc>().add(SearchPO(query)),
            )
          : const Text('Purchase Orders'),
      actions: [
        _totalQuantityBadge(),
        IconButton(
          onPressed: () {
            setState(() {
              _searching = !_searching;
              if (!_searching) {
                _searchController.clear();
                context.read<POBloc>().add(ClearSearch());
              }
            });
          },
          icon: Icon(_searching ? Icons.close : Icons.search),
        ),
        IconButton(
          onPressed: () => context.read<POBloc>().add(RefreshPOList()),
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          onPressed: () => context.push('/purchase-orders/new'),
          icon: const Icon(Icons.add),
        ),
      ],
    ),
    body: BlocConsumer<POBloc, POState>(
      listener: (context, state) {
        if (state is POSuccess || state is POError) {
          final message = state is POSuccess
              ? state.message
              : (state as POError).message;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }
      },
      buildWhen: (_, state) => state is! POSuccess,
      builder: (context, state) {
        if (state is POLoading || state is PORefreshing || state is POSearching) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is POError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message),
                FilledButton(
                  onPressed: () => context.read<POBloc>().add(LoadPOList()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final items = state is POLoaded
            ? state.items
            : state is POSearchLoaded
                ? state.items
                : <POEntity>[];
        final visibleItems = items.where(_matchesColumnFilters).toList();
        if (visibleItems.isEmpty &&
            state is! POLoading &&
            state is! PORefreshing &&
            state is! POSearching) {
          return const Center(child: Text('No Purchase Orders Found'));
        }
        return _PODataTable(
          items: visibleItems,
          loadingMore: state is POLoading,
          vertical: _vertical,
          horizontal: _horizontal,
          onDelete: _confirmDelete,
          filters: _columnFilters,
          onFilterChanged: _setColumnFilter,
        );
      },
    ),
  );

  Widget _totalQuantityBadge() => BlocBuilder<POBloc, POState>(
    buildWhen: (_, state) => state is POLoaded || state is POSearchLoaded,
    builder: (context, state) {
      final items = state is POLoaded
          ? state.items
          : state is POSearchLoaded
          ? state.items
          : const <POEntity>[];
      final total = items
          .where(_matchesColumnFilters)
          .fold<int>(0, (sum, item) => sum + item.totalQuantity);
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

  Future<void> _confirmDelete(POEntity item) async {
    if (item.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete purchase order?'),
        content: Text('Delete ${item.poNo}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<POBloc>().add(DeletePO(item.id!));
    }
  }
}

class _PODataTable extends StatelessWidget {
  const _PODataTable({
    required this.items,
    required this.loadingMore,
    required this.vertical,
    required this.horizontal,
    required this.onDelete,
    required this.filters,
    required this.onFilterChanged,
  });

  final List<POEntity> items;
  final bool loadingMore;
  final ScrollController vertical;
  final ScrollController horizontal;
  final ValueChanged<POEntity> onDelete;
  final Map<String, String> filters;
  final void Function(String key, String value) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    void openDetail(POEntity item) {
      if (item.id != null) {
        context.push('/purchase-orders/detail/${item.id}', extra: item);
      }
    }

    Widget detailCell(POEntity item, Widget child) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: kIsWeb ? null : () => openDetail(item),
            onDoubleTap: kIsWeb ? () => openDetail(item) : null,
            child: child,
          ),
        );

    final rows = [
      ...items.asMap().entries.map((entry) {
        final item = entry.value;
        return DataRow(
          color: WidgetStateProperty.all(
            entry.key.isEven ? Colors.grey.shade50 : null,
          ),
          onSelectChanged: kIsWeb ? null : (_) => openDetail(item),
          cells: [
            // SRS Rule 1: show the auto-generated stored Sl., not the row
            // position, so the list matches the detail view.
            DataCell(detailCell(item, Text(item.sl.toString()))),
            DataCell(detailCell(
                item, Text(DateFormat('dd/MM/yyyy').format(item.poDate)))),
            DataCell(detailCell(item, Text(item.poNo))),
            DataCell(detailCell(item, Text('${item.totalQuantity}'))),
            DataCell(detailCell(
                item, Text(item.totalValue.toStringAsFixed(2)))),
            DataCell(detailCell(item, Text(item.entryPerson))),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: item.id == null
                        ? null
                        : () => context.push(
                            '/purchase-orders/edit/${item.id}',
                            extra: item,
                          ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onDelete(item),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    ];
    if (loadingMore) {
      rows.add(
        const DataRow(
          cells: [
            DataCell(CircularProgressIndicator()),
            DataCell(SizedBox.shrink()),
            DataCell(SizedBox.shrink()),
            DataCell(SizedBox.shrink()),
            DataCell(SizedBox.shrink()),
            DataCell(SizedBox.shrink()),
            DataCell(SizedBox.shrink()),
          ],
        ),
      );
    }
    return Scrollbar(
      controller: vertical,
      child: SingleChildScrollView(
        controller: vertical,
        padding: const EdgeInsets.all(12),
        child: Scrollbar(
          controller: horizontal,
          thumbVisibility: true,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: horizontal,
            scrollDirection: Axis.horizontal,
            child: DataTable(
                columnSpacing: 24,
                horizontalMargin: 12,
                border: TableBorder.all(color: Colors.grey.shade300),
                headingRowColor: WidgetStateProperty.all(
                  Colors.blueGrey.shade50,
                ),
                dataRowMinHeight: 48,
                columns: [
                  _filterColumn('SL', 'sl'),
                  _filterColumn('PO Date', 'date'),
                  _filterColumn('PO No', 'po'),
                  _filterColumn('Total Qty', 'quantity'),
                  _filterColumn('Total Value', 'value'),
                  _filterColumn('Entry Person', 'entry'),
                  DataColumn(
                    label: Text(
                      'Action',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: rows,
            ),
          ),
        ),
      ),
    );
  }

  DataColumn _filterColumn(String label, String key) {
    return DataColumn(
      label: ExcelColumnFilterHeader(
        label: label,
        value: filters[key] ?? '',
        onChanged: (value) => onFilterChanged(key, value),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/po_entity.dart';
import '../../blocs/purchase_order/po_bloc.dart';
import '../../blocs/purchase_order/po_event.dart';
import '../../blocs/purchase_order/po_state.dart';

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
        if (items.isEmpty &&
            state is! POLoading &&
            state is! PORefreshing &&
            state is! POSearching) {
          return const Center(child: Text('No Purchase Orders Found'));
        }
        return _PODataTable(
          items: items,
          loadingMore: state is POLoading,
          vertical: _vertical,
          horizontal: _horizontal,
          onDelete: _confirmDelete,
        );
      },
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
  });

  final List<POEntity> items;
  final bool loadingMore;
  final ScrollController vertical;
  final ScrollController horizontal;
  final ValueChanged<POEntity> onDelete;

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
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1100),
              child: DataTable(
                columnSpacing: 24,
                horizontalMargin: 12,
                border: TableBorder.all(color: Colors.grey.shade300),
                headingRowColor: WidgetStateProperty.all(
                  Colors.blueGrey.shade50,
                ),
                dataRowMinHeight: 48,
                columns: const [
                  DataColumn(
                    label: Text(
                      'SL',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'PO Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'PO No',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Total Qty',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Total Value',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Entry Person',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
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
      ),
    );
  }
}

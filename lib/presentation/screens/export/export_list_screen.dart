import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/export_entity.dart';
import '../../blocs/export/export_bloc.dart';
import '../../blocs/export/export_event.dart';
import '../../blocs/export/export_state.dart';

/// Excel-style Export list: serial number, horizontal + vertical scroll and
/// double-click to open the detail view.
class ExportListScreen extends StatefulWidget {
  const ExportListScreen({super.key});

  @override
  State<ExportListScreen> createState() => _ExportListScreenState();
}

class _ExportListScreenState extends State<ExportListScreen> {
  final verticalScroll = ScrollController();
  final horizontalScroll = ScrollController();
  String query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExportBloc>().add(LoadExportList());
    });
    verticalScroll.addListener(() {
      if (verticalScroll.position.pixels >=
          verticalScroll.position.maxScrollExtent - 200) {
        context.read<ExportBloc>().add(LoadMoreExportList());
      }
    });
  }

  @override
  void dispose() {
    verticalScroll.dispose();
    horizontalScroll.dispose();
    super.dispose();
  }

  bool _matches(ExportEntity item) {
    final value = query.toLowerCase();
    if (value.isEmpty) return true;
    return item.poNo.toLowerCase().contains(value) ||
        item.voucherNo.toLowerCase().contains(value) ||
        item.poTagNo.toLowerCase().contains(value) ||
        item.article.toLowerCase().contains(value) ||
        item.color.toLowerCase().contains(value);
  }

  Future<void> _delete(ExportEntity item) async {
    final id = item.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete export record?'),
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
      context.read<ExportBloc>().add(DeleteExport(id));
    }
  }

  void _openDetail(ExportEntity item) =>
      context.push('/export/detail/${item.id}', extra: item);

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
      title: const Text('Export'),
      actions: [
        IconButton(
          tooltip: 'Search',
          icon: const Icon(Icons.search),
          onPressed: () async {
            final bloc = context.read<ExportBloc>();
            final value = await showSearch<String?>(
              context: context,
              delegate: _ExportSearchDelegate(query),
            );
            if (value != null && mounted) {
              setState(() => query = value);
              bloc.add(SearchExport(value));
            }
          },
        ),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<ExportBloc>().add(RefreshExport()),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.push('/export/new'),
      child: const Icon(Icons.add),
    ),
    body: BlocConsumer<ExportBloc, ExportState>(
      listener: (context, state) {
        if (state is ExportSuccess || state is ExportError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state is ExportSuccess
                    ? state.message
                    : (state as ExportError).message,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ExportLoading && state is! ExportLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = state is ExportLoaded
            ? state.items.where(_matches).toList()
            : <ExportEntity>[];
        if (items.isEmpty) {
          return const Center(child: Text('No Export Records'));
        }
        return _table(items);
      },
    ),
  );

  Widget _table(List<ExportEntity> items) => Scrollbar(
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1900),
            child: DataTable(
              columnSpacing: 14,
              headingRowColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              columns: const [
                DataColumn(label: Text('SL')),
                DataColumn(label: Text('Export Date')),
                DataColumn(label: Text('Voucher')),
                DataColumn(label: Text('Factory')),
                DataColumn(label: Text('PO No')),
                DataColumn(label: Text('Tag No')),
                DataColumn(label: Text('Article')),
                DataColumn(label: Text('Color')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Value')),
                DataColumn(label: Text('Entry By')),
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
                    DataCell(Text(_date(item.exportDate))),
                    DataCell(Text(item.voucherNo)),
                    DataCell(Text(item.factoryName)),
                    DataCell(Text(item.poNo)),
                    DataCell(Text(item.effectiveTagNo)),
                    DataCell(Text(item.article)),
                    DataCell(Text(item.color)),
                    DataCell(Text('${item.quantity}')),
                    DataCell(Text(_money(item.exportValue))),
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
                                    '/export/edit/$id',
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
    ),
  );
}

class _ExportSearchDelegate extends SearchDelegate<String?> {
  _ExportSearchDelegate(String initial) {
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

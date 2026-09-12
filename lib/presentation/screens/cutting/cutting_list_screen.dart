import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/cutting_entity.dart';
import '../../blocs/cutting/cutting_bloc.dart';
import '../../blocs/cutting/cutting_event.dart';
import '../../blocs/cutting/cutting_state.dart';

class CuttingListScreen extends StatefulWidget {
  const CuttingListScreen({super.key});
  @override
  State<CuttingListScreen> createState() => _CuttingListScreenState();
}

class _CuttingListScreenState extends State<CuttingListScreen> {
  final scroll = ScrollController();
  final horizontalScroll = ScrollController();
  String query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CuttingBloc>().add(LoadCuttingList());
    });
    scroll.addListener(() {
      if (scroll.position.pixels >= scroll.position.maxScrollExtent - 200) {
        context.read<CuttingBloc>().add(LoadMoreCuttingList());
      }
    });
  }

  @override
  void dispose() {
    scroll.dispose();
    horizontalScroll.dispose();
    super.dispose();
  }

  bool _matches(CuttingEntity item) {
    final value = query.toLowerCase();
    return item.poNo.toLowerCase().contains(value) ||
        item.voucherNo.toLowerCase().contains(value) ||
        item.tagNo.toLowerCase().contains(value) ||
        item.poTagNo.toLowerCase().contains(value);
  }

  Future<void> _delete(CuttingEntity item) async {
    if (item.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete cutting record?'),
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
      context.read<CuttingBloc>().add(DeleteCutting(item.id!));
    }
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
        IconButton(
          tooltip: 'Search',
          icon: const Icon(Icons.search),
          onPressed: () async {
            final bloc = context.read<CuttingBloc>();
            final value = await showSearch<String?>(
              context: context,
              delegate: _CuttingSearchDelegate(query),
            );
            if (value != null && mounted) {
              setState(() => query = value);
              bloc.add(SearchCutting(value));
            }
          },
        ),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<CuttingBloc>().add(RefreshCutting()),
        ),
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
        return Scrollbar(
          controller: scroll,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.all(12),
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              controller: horizontalScroll,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1500),
                child: DataTable(
                  columnSpacing: 14,
                  headingRowColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  columns: const [
                    DataColumn(label: Text('SL')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Voucher')),
                    DataColumn(label: Text('PO No')),
                    DataColumn(label: Text('Tag No')),
                    DataColumn(label: Text('Article')),
                    DataColumn(label: Text('Color')),
                    DataColumn(label: Text('Cutting Qty')),
                    DataColumn(label: Text('Entry Person')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: items
                      .asMap()
                      .entries
                      .map(
                        (entry) => DataRow(
                          onSelectChanged: entry.value.id == null
                              ? null
                              : (_) => context.push(
                                  '/cutting/detail/${entry.value.id}',
                                  extra: entry.value,
                                ),
                          cells: [
                            DataCell(
                              GestureDetector(
                                onDoubleTap: entry.value.id == null
                                    ? null
                                    : () => context.push(
                                        '/cutting/detail/${entry.value.id}',
                                        extra: entry.value,
                                      ),
                                child: Text('${entry.key + 1}'),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${entry.value.cuttingDate.day.toString().padLeft(2, '0')}/${entry.value.cuttingDate.month.toString().padLeft(2, '0')}/${entry.value.cuttingDate.year}',
                              ),
                            ),
                            DataCell(Text(entry.value.voucherNo)),
                            DataCell(Text(entry.value.poNo)),
                            DataCell(
                              Text(
                                entry.value.tagNo.isEmpty
                                    ? entry.value.poTagNo
                                    : entry.value.tagNo,
                              ),
                            ),
                            DataCell(Text(entry.value.article)),
                            DataCell(Text(entry.value.color)),
                            DataCell(
                              Text(
                                '${entry.value.cuttingQuantity == 0 ? entry.value.quantity : entry.value.cuttingQuantity}',
                              ),
                            ),
                            DataCell(Text(entry.value.entryPerson)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit',
                                    color: Colors.blue,
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: entry.value.id == null
                                        ? null
                                        : () => context.push(
                                            '/cutting/edit/${entry.value.id}',
                                            extra: entry.value,
                                          ),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    color: Colors.red,
                                    icon: const Icon(Icons.delete_outline),
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
        );
      },
    ),
  );
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

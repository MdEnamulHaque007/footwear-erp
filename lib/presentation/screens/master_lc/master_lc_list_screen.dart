import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/master_lc_entity.dart';
import '../../blocs/master_lc/master_lc_bloc.dart';
import '../../blocs/master_lc/master_lc_event.dart';
import '../../blocs/master_lc/master_lc_state.dart';
import '../../routes/route_constants.dart';

class MasterLCListScreen extends StatefulWidget {
  const MasterLCListScreen({super.key});

  @override
  State<MasterLCListScreen> createState() => _MasterLCListScreenState();
}

class _MasterLCListScreenState extends State<MasterLCListScreen> {
  final _searchController = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MasterLCBloc>().add(LoadMasterLCList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search tag, company, project or LC no.',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text('Master LC List'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Dashboard',
          onPressed: () => context.go(RouteConstants.dashboard),
        ),
        actions: [
          IconButton(
            tooltip: _searching ? 'Close search' : 'Search',
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) _searchController.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<MasterLCBloc>().add(LoadMasterLCList()),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Master LC',
            onPressed: () => context.push('/master-lc/new'),
          ),
        ],
      ),
      body: BlocConsumer<MasterLCBloc, MasterLCState>(
        listener: (context, state) {
          if (state is MasterLCSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is MasterLCError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is MasterLCLoading &&
              context.read<MasterLCBloc>().state is! MasterLCLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MasterLCError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<MasterLCBloc>().add(LoadMasterLCList()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is MasterLCLoaded) {
            return _buildExcelTable(_filteredItems(state.items));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/master-lc/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<MasterLCEntity> _filteredItems(List<MasterLCEntity> items) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items.where((item) {
      return item.tagNo.toLowerCase().contains(query) ||
          item.company.toLowerCase().contains(query) ||
          item.project.toLowerCase().contains(query) ||
          item.lcNo.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildExcelTable(List<MasterLCEntity> items) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Master LC records found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 20,
          horizontalMargin: 16,
          headingRowColor: WidgetStateProperty.all(Colors.blueGrey.shade50),
          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
          columns: const [
            DataColumn(
              label: Text('SL', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(
                'Tag No',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Project',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Company',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'LC No',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'SC No',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'TT No',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(
                'Value (\$)',
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
          rows: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>(
                (states) => index.isEven ? Colors.grey.shade50 : Colors.white,
              ),
              onSelectChanged: item.id == null
                  ? null
                  : (_) => context.push(
                        '/master-lc/detail/${item.id}',
                        extra: item,
                      ),
              cells: [
                DataCell(Text((index + 1).toString())),
                DataCell(
                  InkWell(
                    onTap: () => context.push(
                      '/master-lc/detail/${item.id}',
                      extra: item,
                    ),
                    child: Text(
                      item.tagNo,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(item.project)),
                DataCell(Text(item.company)),
                DataCell(Text(item.lcNo.isEmpty ? '-' : item.lcNo)),
                DataCell(Text(item.scNo.isEmpty ? '-' : item.scNo)),
                DataCell(Text(item.ttNo.isEmpty ? '-' : item.ttNo)),
                DataCell(Text(_formatQuantity(item.masterLcQuantity))),
                DataCell(Text(_formatValue(item.masterLcValue))),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.visibility,
                          size: 18,
                          color: Colors.blue,
                        ),
                        tooltip: 'View Details',
                        onPressed: () =>
                            context.push(
                              '/master-lc/detail/${item.id}',
                              extra: item,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.blue,
                        ),
                        tooltip: 'Edit',
                        onPressed: item.id == null
                            ? null
                            : () => context.push(
                                '/master-lc/edit/${item.id}',
                                extra: item,
                              ),
                      ),
                      if (item.id != null)
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.red,
                          ),
                          tooltip: 'Delete',
                          onPressed: item.id == null
                              ? null
                              : () => _showDeleteDialog(
                                  context,
                                  item.id!,
                                  item.tagNo,
                                ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatQuantity(int value) => NumberFormat('#,##0').format(value);
  String _formatValue(double value) =>
      NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value);

  void _showDeleteDialog(BuildContext context, String id, String tagNo) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Master LC'),
        content: Text('Are you sure you want to delete Master LC "$tagNo"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<MasterLCBloc>().add(DeleteMasterLC(id));
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/reports/warehouse_report_entity.dart';
import '../../blocs/reports/warehouse_report_bloc.dart';
import '../../blocs/reports/warehouse_report_event.dart';
import '../../blocs/reports/warehouse_report_state.dart';
import '../../routes/route_constants.dart';
import '../../widgets/app_drawer.dart';

class WarehouseReportScreen extends StatefulWidget {
  const WarehouseReportScreen({super.key});

  @override
  State<WarehouseReportScreen> createState() => _WarehouseReportScreenState();
}

class _WarehouseReportScreenState extends State<WarehouseReportScreen> {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _numberFormat = NumberFormat('#,##0');
  final _verticalController = ScrollController();
  final _horizontalController = ScrollController();
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  void _generate() => context.read<WarehouseReportBloc>().add(
    LoadWarehouseReport(fromDate: _fromDate, toDate: _toDate),
  );

  Future<void> _pickDate(bool isFrom) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      if (isFrom) {
        _fromDate = selected;
        if (_toDate.isBefore(selected)) {
          _toDate = selected;
        }
      } else {
        _toDate = selected;
        if (selected.isBefore(_fromDate)) {
          _fromDate = selected;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leadingWidth: 96,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(RouteConstants.reports),
            ),
            Builder(
              builder: (drawerContext) => IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(drawerContext).openDrawer(),
              ),
            ),
          ],
        ),
        title: const Text('Production Warehouse Report'),
      ),
      body: BlocConsumer<WarehouseReportBloc, WarehouseReportState>(
        listener: (context, state) {
          if (state case WarehouseReportExported(:final message)) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          } else if (state case WarehouseReportError(:final message)) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) => Column(
          children: [
            _filters(),
            Expanded(child: _body(state)),
          ],
        ),
      ),
    );
  }

  Widget _filters() => Padding(
    padding: const EdgeInsets.all(16),
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () => _pickDate(true),
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text('From: ${_dateFormat.format(_fromDate)}'),
        ),
        OutlinedButton.icon(
          onPressed: () => _pickDate(false),
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text('To: ${_dateFormat.format(_toDate)}'),
        ),
        FilledButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.table_chart_outlined),
          label: const Text('Generate Report'),
        ),
      ],
    ),
  );

  Widget _body(WarehouseReportState state) => switch (state) {
    WarehouseReportInitial() || WarehouseReportLoading() => const Center(
      child: CircularProgressIndicator(),
    ),
    WarehouseReportError(:final message) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
    WarehouseReportLoaded(:final result) => _table(result),
    WarehouseReportExported(:final result) => _table(result),
  };

  Widget _table(WarehouseReportResult result) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
          'Date Range: ${_dateFormat.format(result.fromDate)} → '
          '${_dateFormat.format(result.toDate)}   •   ${result.rows.length} rows',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      Expanded(
        child: Scrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalController,
            child: Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              notificationPredicate: (notification) => notification.depth == 1,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 1400),
                  child: DataTable(
                    columnSpacing: 24,
                    headingRowColor: WidgetStatePropertyAll(
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    columns: const [
                      DataColumn(label: Text('Company')),
                      DataColumn(label: Text('Project')),
                      DataColumn(label: Text('PO No')),
                      DataColumn(label: Text('Article')),
                      DataColumn(label: Text('Color')),
                      DataColumn(label: Text('PO Qty'), numeric: true),
                      DataColumn(label: Text('Cutting Qty'), numeric: true),
                      DataColumn(label: Text('Sewing Qty'), numeric: true),
                      DataColumn(label: Text('Lasting Qty'), numeric: true),
                    ],
                    rows: [
                      for (var index = 0; index < result.rows.length; index++)
                        _row(result.rows[index], index),
                      _totalRow(result.summary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => context.read<WarehouseReportBloc>().add(
                const ExportWarehouseReportExcel(),
              ),
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Export Excel'),
            ),
            FilledButton.icon(
              onPressed: () => context.read<WarehouseReportBloc>().add(
                const ExportWarehouseReportPdf(),
              ),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print PDF'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.read<WarehouseReportBloc>().add(
                const RefreshWarehouseReport(),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    ],
  );

  DataRow _row(WarehouseReportRow row, int index) => DataRow(
    color: index.isOdd
        ? WidgetStatePropertyAll(
            Theme.of(context).colorScheme.surfaceContainerLow,
          )
        : null,
    cells: [
      DataCell(Text(row.company)),
      DataCell(Text(row.project)),
      DataCell(Text(row.poNo)),
      DataCell(Text(row.article)),
      DataCell(Text(row.color)),
      DataCell(Text(_displayQuantity(row.poQuantity))),
      DataCell(Text(_displayQuantity(row.cuttingQuantity))),
      DataCell(Text(_displayQuantity(row.sewingQuantity))),
      DataCell(Text(_displayQuantity(row.lastingQuantity))),
    ],
  );

  DataRow _totalRow(WarehouseReportSummary summary) {
    const bold = TextStyle(fontWeight: FontWeight.bold);
    return DataRow(
      color: WidgetStatePropertyAll(
        Theme.of(context).colorScheme.secondaryContainer,
      ),
      cells: [
        const DataCell(Text('TOTAL', style: bold)),
        const DataCell(Text('')),
        const DataCell(Text('')),
        const DataCell(Text('')),
        const DataCell(Text('')),
        DataCell(
          Text(_numberFormat.format(summary.totalPoQuantity), style: bold),
        ),
        DataCell(
          Text(_numberFormat.format(summary.totalCuttingQuantity), style: bold),
        ),
        DataCell(
          Text(_numberFormat.format(summary.totalSewingQuantity), style: bold),
        ),
        DataCell(
          Text(_numberFormat.format(summary.totalLastingQuantity), style: bold),
        ),
      ],
    );
  }

  String _displayQuantity(int quantity) =>
      quantity == 0 ? '-' : _numberFormat.format(quantity);
}

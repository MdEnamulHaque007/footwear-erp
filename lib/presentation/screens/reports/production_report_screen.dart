/// ============================================================================
/// ফাইল: lib/presentation/screens/reports/production_report_screen.dart
/// স্তর: Presentation Screen | মডিউল: Production/Lasting
/// উদ্দেশ্য: Production/Lasting মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: ProductionReportScreen, _ProductionReportScreenState
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/reports/production_report_entity.dart';
import '../../blocs/reports/production_report_bloc.dart';
import '../../blocs/reports/production_report_event.dart';
import '../../blocs/reports/production_report_state.dart';

/// Production Warehouse Report.
///
/// Implements the Google Sheet `Production Report` formula as a Flutter screen:
/// a date range + search filter, the distinct PO lines touched inside that range
/// across Cutting / Sewing / Lasting, and a grand-total row.
class ProductionReportScreen extends StatefulWidget {
  const ProductionReportScreen({super.key});

  @override
  State<ProductionReportScreen> createState() => _ProductionReportScreenState();
}

class _ProductionReportScreenState extends State<ProductionReportScreen> {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _numberFormat = NumberFormat('#,##0');
  static final _timeFormat = DateFormat('hh:mm a');

  final _searchController = TextEditingController();
  final _verticalScroll = ScrollController();
  final _horizontalScroll = ScrollController();

  late DateTime _fromDate;
  late DateTime _toDate;

  /// Ticks every second so the header clock stays live.
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _searchController.dispose();
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5, now.month, now.day),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _fromDate = selected;
        if (_toDate.isBefore(_fromDate)) _toDate = _fromDate;
      } else {
        _toDate = selected;
        if (_toDate.isBefore(_fromDate)) _fromDate = _toDate;
      }
    });
    _reload();
  }

  void _reload() {
    context.read<ProductionReportBloc>().add(
      LoadProductionReport(
        fromDate: _fromDate,
        toDate: _toDate,
        search: _searchController.text.trim(),
      ),
    );
  }

  void _clearFilters() {
    final now = DateTime.now();
    _searchController.clear();
    setState(() {
      _fromDate = DateTime(now.year, now.month, 1);
      _toDate = now;
    });
    context.read<ProductionReportBloc>().add(ClearFilters());
  }

  @override
  Widget build(BuildContext context) {
    if (context.read<ProductionReportBloc>().state is ProductionReportInitial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reload();
      });
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to Dashboard',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Production Warehouse Report'),
      ),
      body: BlocConsumer<ProductionReportBloc, ProductionReportState>(
        listenWhen: (previous, current) =>
            current is ProductionReportExported ||
            current is ProductionReportError,
        listener: (context, state) {
          final String? message = switch (state) {
            ProductionReportExported(:final message) => message,
            ProductionReportError(:final message) => message,
            _ => null,
          };
          if (message == null) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (context, state) => Column(
          children: [
            _filterBar(),
            _reportInfo(state),
            const Divider(height: 1),
            Expanded(child: _body(state)),
          ],
        ),
      ),
    );
  }

  Widget _filterBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _dateButton('From', _fromDate, () => _pickDate(isFrom: true)),
        _dateButton('To', _toDate, () => _pickDate(isFrom: false)),
        SizedBox(
          width: 240,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search',
              hintText: 'PO, Article, Color, Company, Project',
              prefixIcon: Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _reload(),
          ),
        ),
        IconButton(
          tooltip: 'Search',
          icon: const Icon(Icons.search),
          onPressed: _reload,
        ),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              context.read<ProductionReportBloc>().add(RefreshReport()),
        ),
        TextButton.icon(
          onPressed: _clearFilters,
          icon: const Icon(Icons.filter_alt_off),
          label: const Text('Clear Filters'),
        ),
      ],
    ),
  );

  Widget _dateButton(String label, DateTime value, VoidCallback onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.calendar_today, size: 16),
        label: Text('$label: ${_dateFormat.format(value)}'),
      );

  Widget _reportInfo(ProductionReportState state) {
    final now = DateTime.now();
    final rowCount = state is ProductionReportLoaded ? state.rows.length : 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Report Date: ${_dateFormat.format(now)}   '
              'Time: ${_timeFormat.format(now)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            'Rows: $rowCount',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _body(ProductionReportState state) => switch (state) {
    ProductionReportLoading() => const Center(
      child: CircularProgressIndicator(),
    ),
    ProductionReportError(:final message) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _reload, child: const Text('Retry')),
          ],
        ),
      ),
    ),
    ProductionReportEmpty() => const Center(
      child: Text('No production activity in the selected date range'),
    ),
    ProductionReportLoaded(:final result) => _reportTable(result),
    _ => const SizedBox.shrink(),
  };

  Widget _reportTable(ProductionReportResult result) => Column(
    children: [
      Expanded(
        child: Scrollbar(
          controller: _horizontalScroll,
          thumbVisibility: true,
          notificationPredicate: (notification) => notification.depth == 1,
          child: SingleChildScrollView(
            controller: _verticalScroll,
            child: Scrollbar(
              controller: _verticalScroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalScroll,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 1200),
                  child: DataTable(
                    columnSpacing: 18,
                    headingRowColor: WidgetStatePropertyAll(
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    columns: const [
                      DataColumn(label: Text('Company')),
                      DataColumn(label: Text('Project')),
                      DataColumn(label: Text('PO')),
                      DataColumn(label: Text('Article')),
                      DataColumn(label: Text('Color')),
                      DataColumn(label: Text('PO Qty'), numeric: true),
                      DataColumn(label: Text('Cutting'), numeric: true),
                      DataColumn(label: Text('Sewing'), numeric: true),
                      DataColumn(label: Text('Lasting'), numeric: true),
                    ],
                    rows: [
                      for (final row in result.rows)
                        DataRow(
                          cells: [
                            DataCell(Text(row.company)),
                            DataCell(Text(row.project)),
                            DataCell(Text(row.po)),
                            DataCell(Text(row.article)),
                            DataCell(Text(row.color)),
                            DataCell(
                              Text(_numberFormat.format(row.poQuantity)),
                            ),
                            DataCell(
                              Text(_numberFormat.format(row.cuttingQuantity)),
                            ),
                            DataCell(
                              Text(_numberFormat.format(row.sewingQuantity)),
                            ),
                            DataCell(
                              Text(_numberFormat.format(row.lastingQuantity)),
                            ),
                          ],
                        ),
                      _totalRow(result.summary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      _actions(result),
    ],
  );

  /// Grand-total row: the sheet's TOTAL line.
  DataRow _totalRow(ProductionReportSummary summary) {
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
        DataCell(Text(_numberFormat.format(summary.totalPOQuantity),
            style: bold)),
        DataCell(Text(_numberFormat.format(summary.totalCuttingQuantity),
            style: bold)),
        DataCell(Text(_numberFormat.format(summary.totalSewingQuantity),
            style: bold)),
        DataCell(Text(_numberFormat.format(summary.totalLastingQuantity),
            style: bold)),
      ],
    );
  }

  Widget _actions(ProductionReportResult result) => Padding(
    padding: const EdgeInsets.all(12),
    child: Wrap(
      spacing: 12,
      alignment: WrapAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: () => context.read<ProductionReportBloc>().add(
            ExportReportRequested(result, asPdf: false),
          ),
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Export Excel'),
        ),
        FilledButton.icon(
          onPressed: () => context.read<ProductionReportBloc>().add(
            ExportReportRequested(result, asPdf: true),
          ),
          icon: const Icon(Icons.print_outlined),
          label: const Text('Print PDF'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back'),
        ),
      ],
    ),
  );
}

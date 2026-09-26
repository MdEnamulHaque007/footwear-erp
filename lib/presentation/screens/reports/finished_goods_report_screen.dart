/// ============================================================================
/// ফাইল: lib/presentation/screens/reports/finished_goods_report_screen.dart
/// স্তর: Presentation Screen | মডিউল: Reports
/// উদ্দেশ্য: Reports মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: FinishedGoodsReportScreen, _FinishedGoodsReportScreenState
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/reports/finished_goods_report_entity.dart';
import '../../blocs/reports/finished_goods_report_bloc.dart';
import '../../blocs/reports/finished_goods_report_event.dart';
import '../../blocs/reports/finished_goods_report_state.dart';
import '../../routes/route_constants.dart';

/// Finished Goods Report.
///
/// Implements the Google Sheet `Finished Goods Report` formula as a Flutter
/// screen: a date range + search filter, one row per (PO, Article, Color) line
/// with Opening Balance / FG In / Total / FG Out / Stock, and a grand-total row.
class FinishedGoodsReportScreen extends StatefulWidget {
  const FinishedGoodsReportScreen({super.key});

  @override
  State<FinishedGoodsReportScreen> createState() =>
      _FinishedGoodsReportScreenState();
}

class _FinishedGoodsReportScreenState extends State<FinishedGoodsReportScreen> {
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
    context.read<FinishedGoodsReportBloc>().add(
      LoadFinishedGoodsReport(
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
    context.read<FinishedGoodsReportBloc>().add(ClearFilters());
  }

  @override
  Widget build(BuildContext context) {
    if (context.read<FinishedGoodsReportBloc>().state
        is FinishedGoodsReportInitial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reload();
      });
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to Reports',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteConstants.reports),
        ),
        title: const Text('Finished Goods Report'),
      ),
      body: BlocConsumer<FinishedGoodsReportBloc, FinishedGoodsReportState>(
        listenWhen: (previous, current) =>
            current is FinishedGoodsReportExported ||
            current is FinishedGoodsReportError,
        listener: (context, state) {
          final String? message = switch (state) {
            FinishedGoodsReportExported(:final message) => message,
            FinishedGoodsReportError(:final message) => message,
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
              hintText: 'PO, Article, Color',
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
              context.read<FinishedGoodsReportBloc>().add(RefreshReport()),
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

  Widget _reportInfo(FinishedGoodsReportState state) {
    final now = DateTime.now();
    final rowCount = state is FinishedGoodsReportLoaded
        ? state.rows.length
        : 0;
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

  Widget _body(FinishedGoodsReportState state) => switch (state) {
    FinishedGoodsReportLoading() => const Center(
      child: CircularProgressIndicator(),
    ),
    FinishedGoodsReportError(:final message) => Center(
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
    FinishedGoodsReportEmpty() => const Center(
      child: Text('No finished goods movement in the selected date range'),
    ),
    FinishedGoodsReportLoaded(:final result) => _reportTable(result),
    _ => const SizedBox.shrink(),
  };

  Widget _reportTable(FinishedGoodsReportResult result) => Column(
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
                      DataColumn(label: Text('PO')),
                      DataColumn(label: Text('Article')),
                      DataColumn(label: Text('Color')),
                      DataColumn(
                        label: Text('Opening Balance'),
                        numeric: true,
                      ),
                      DataColumn(label: Text('FG In'), numeric: true),
                      DataColumn(label: Text('Total'), numeric: true),
                      DataColumn(label: Text('FG Out'), numeric: true),
                      DataColumn(label: Text('Stock'), numeric: true),
                    ],
                    rows: [
                      for (final row in result.rows)
                        DataRow(
                          cells: [
                            DataCell(Text(row.po)),
                            DataCell(Text(row.article)),
                            DataCell(Text(row.color)),
                            DataCell(
                              Text(_numberFormat.format(row.openingBalance)),
                            ),
                            DataCell(Text(_numberFormat.format(row.fgIn))),
                            DataCell(Text(_numberFormat.format(row.total))),
                            DataCell(Text(_numberFormat.format(row.fgOut))),
                            DataCell(Text(_numberFormat.format(row.stock))),
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
  DataRow _totalRow(FinishedGoodsReportSummary summary) {
    const bold = TextStyle(fontWeight: FontWeight.bold);
    return DataRow(
      color: WidgetStatePropertyAll(
        Theme.of(context).colorScheme.secondaryContainer,
      ),
      cells: [
        const DataCell(Text('TOTAL', style: bold)),
        const DataCell(Text('')),
        const DataCell(Text('')),
        DataCell(
          Text(_numberFormat.format(summary.totalOpeningBalance), style: bold),
        ),
        DataCell(Text(_numberFormat.format(summary.totalFGIn), style: bold)),
        DataCell(Text(_numberFormat.format(summary.totalTotal), style: bold)),
        DataCell(Text(_numberFormat.format(summary.totalFGOut), style: bold)),
        DataCell(Text(_numberFormat.format(summary.totalStock), style: bold)),
      ],
    );
  }

  Widget _actions(FinishedGoodsReportResult result) => Padding(
    padding: const EdgeInsets.all(12),
    child: Wrap(
      spacing: 12,
      alignment: WrapAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: () => context.read<FinishedGoodsReportBloc>().add(
            ExportReportRequested(result, asPdf: false),
          ),
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Export Excel'),
        ),
        FilledButton.icon(
          onPressed: () => context.read<FinishedGoodsReportBloc>().add(
            ExportReportRequested(result, asPdf: true),
          ),
          icon: const Icon(Icons.print_outlined),
          label: const Text('Print PDF'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go(RouteConstants.reports),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back'),
        ),
      ],
    ),
  );
}

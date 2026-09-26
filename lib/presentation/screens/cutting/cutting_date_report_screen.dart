/// ============================================================================
/// ফাইল: lib/presentation/screens/cutting/cutting_date_report_screen.dart
/// স্তর: Presentation Screen | মডিউল: Cutting
/// উদ্দেশ্য: Cutting মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: CuttingDateReportScreen, _CuttingDateReportScreenState
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/cutting_entity.dart';

/// A read-only, date-wise view of the Cutting records already loaded by the
/// Cutting page. This keeps the report scoped to Cutting and avoids exposing it
/// as a separate application module.
class CuttingDateReportScreen extends StatefulWidget {
  const CuttingDateReportScreen({required this.items, super.key});

  final List<CuttingEntity> items;

  @override
  State<CuttingDateReportScreen> createState() =>
      _CuttingDateReportScreenState();
}

class _CuttingDateReportScreenState extends State<CuttingDateReportScreen> {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _numberFormat = NumberFormat('#,##0');

  final _verticalScroll = ScrollController();
  final _horizontalScroll = ScrollController();
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    final sorted = List<CuttingEntity>.of(widget.items)
      ..sort((a, b) => a.cuttingDate.compareTo(b.cuttingDate));
    final today = _dateOnly(DateTime.now());
    _fromDate = sorted.isEmpty ? today : _dateOnly(sorted.first.cuttingDate);
    _toDate = sorted.isEmpty ? today : _dateOnly(sorted.last.cuttingDate);
  }

  @override
  void dispose() {
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  List<CuttingEntity> get _filteredItems {
    final endExclusive = _toDate.add(const Duration(days: 1));
    final result = widget.items.where((item) {
      final date = item.cuttingDate;
      return !date.isBefore(_fromDate) && date.isBefore(endExclusive);
    }).toList()
      ..sort((a, b) {
        final byDate = b.cuttingDate.compareTo(a.cuttingDate);
        return byDate != 0 ? byDate : a.voucherNo.compareTo(b.voucherNo);
      });
    return result;
  }

  Map<DateTime, List<CuttingEntity>> get _dateGroups {
    final groups = <DateTime, List<CuttingEntity>>{};
    for (final item in _filteredItems) {
      groups.putIfAbsent(_dateOnly(item.cuttingDate), () => []).add(item);
    }
    return groups;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final groups = _dateGroups;
    final totalQuantity = items.fold<int>(
      0,
      (sum, item) => sum + item.cuttingQuantity,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Cutting Date-wise Report')),
      body: Column(
        children: [
          _filters(),
          _summary(
            workingDays: groups.length,
            entries: items.length,
            totalQuantity: totalQuantity,
          ),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text('No Cutting records in selected date range'),
                  )
                : _table(groups),
          ),
        ],
      ),
    );
  }

  Widget _filters() => Padding(
    padding: const EdgeInsets.all(12),
    child: Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _dateButton('From', _fromDate, () => _pickDate(isFrom: true)),
        _dateButton('To', _toDate, () => _pickDate(isFrom: false)),
        TextButton.icon(
          onPressed: () {
            final sorted = List<CuttingEntity>.of(widget.items)
              ..sort((a, b) => a.cuttingDate.compareTo(b.cuttingDate));
            if (sorted.isEmpty) return;
            setState(() {
              _fromDate = _dateOnly(sorted.first.cuttingDate);
              _toDate = _dateOnly(sorted.last.cuttingDate);
            });
          },
          icon: const Icon(Icons.filter_alt_off),
          label: const Text('Show All'),
        ),
      ],
    ),
  );

  Widget _dateButton(String label, DateTime date, VoidCallback onPressed) =>
      OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.calendar_today_outlined, size: 17),
        label: Text('$label: ${_dateFormat.format(date)}'),
      );

  Widget _summary({
    required int workingDays,
    required int entries,
    required int totalQuantity,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    child: Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _summaryCard('Working Days', _numberFormat.format(workingDays)),
        _summaryCard('Entries', _numberFormat.format(entries)),
        _summaryCard('Total Cutting Qty', _numberFormat.format(totalQuantity)),
      ],
    ),
  );

  Widget _summaryCard(String label, String value) => Container(
    constraints: const BoxConstraints(minWidth: 160),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );

  Widget _table(Map<DateTime, List<CuttingEntity>> groups) {
    final rows = <DataRow>[];
    for (final group in groups.entries) {
      final dailyTotal = group.value.fold<int>(
        0,
        (sum, item) => sum + item.cuttingQuantity,
      );
      for (final item in group.value) {
        rows.add(
          DataRow(
            cells: [
              DataCell(Text(_dateFormat.format(group.key))),
              DataCell(Text(item.voucherNo)),
              DataCell(Text(item.factoryName)),
              DataCell(Text(item.project)),
              DataCell(Text(item.poNo)),
              DataCell(Text(item.article)),
              DataCell(Text(item.color)),
              DataCell(Text(_numberFormat.format(item.cuttingQuantity))),
              DataCell(Text(item.entryPerson)),
            ],
          ),
        );
      }
      rows.add(
        DataRow(
          color: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.primaryContainer,
          ),
          cells: [
            DataCell(
              Text(
                '${_dateFormat.format(group.key)} Total',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            DataCell(
              Text(
                _numberFormat.format(dailyTotal),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const DataCell(Text('')),
          ],
        ),
      );
    }

    return Scrollbar(
      controller: _verticalScroll,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalScroll,
        padding: const EdgeInsets.all(12),
        child: Scrollbar(
          controller: _horizontalScroll,
          thumbVisibility: true,
          notificationPredicate: (notification) => notification.depth == 1,
          child: SingleChildScrollView(
            controller: _horizontalScroll,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              columns: const [
                DataColumn(label: Text('Cutting Date')),
                DataColumn(label: Text('Voucher No')),
                DataColumn(label: Text('Factory')),
                DataColumn(label: Text('Project')),
                DataColumn(label: Text('PO No')),
                DataColumn(label: Text('Article')),
                DataColumn(label: Text('Color')),
                DataColumn(label: Text('Cutting Qty'), numeric: true),
                DataColumn(label: Text('Entry Person')),
              ],
              rows: rows,
            ),
          ),
        ),
      ),
    );
  }
}

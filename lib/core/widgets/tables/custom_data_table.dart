import 'package:flutter/material.dart';

class CustomDataTable extends StatelessWidget {
  const CustomDataTable({super.key, required this.columns, required this.rows});
  final List<DataColumn> columns;
  final List<DataRow> rows;
  @override
  Widget build(BuildContext context) => DataTable(columns: columns, rows: rows);
}

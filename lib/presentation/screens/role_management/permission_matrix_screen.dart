import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class PermissionMatrixScreen extends StatelessWidget {
  const PermissionMatrixScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Permission matrix')),
    body: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Module')),
          DataColumn(label: Text('View')),
          DataColumn(label: Text('Create')),
          DataColumn(label: Text('Edit')),
          DataColumn(label: Text('Delete')),
        ],
        rows: AppConstants.permissionModules
            .map(
              (module) => DataRow(
                cells: [
                  DataCell(Text(module)),
                  ...AppConstants.permissionActions.map(
                    (_) => const DataCell(Icon(Icons.check_box_outline_blank)),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    ),
  );
}

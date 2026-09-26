/// ============================================================================
/// ফাইল: lib/presentation/screens/role_management/permission_matrix_screen.dart
/// স্তর: Presentation Screen | মডিউল: Role Management
/// উদ্দেশ্য: Role Management মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: PermissionMatrixScreen
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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

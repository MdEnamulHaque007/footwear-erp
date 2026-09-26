/// ============================================================================
/// ফাইল: lib/presentation/screens/role_management/role_list_screen.dart
/// স্তর: Presentation Screen | মডিউল: Role Management
/// উদ্দেশ্য: Role Management মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: RoleListScreen
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/admin_sidebar_widget.dart';
import '../../blocs/role_management/role_management_bloc.dart';
import '../../blocs/role_management/role_management_state.dart';

class RoleListScreen extends StatelessWidget {
  const RoleListScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Roles')),
    drawer: const AdminSidebarWidget(),
    body: BlocBuilder<RoleManagementBloc, RoleManagementState>(
      builder: (_, state) {
        if (state is RoleManagementLoading || state is RoleManagementInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is RoleManagementError) {
          return Center(child: Text(state.message));
        }
        final roles = state is RoleManagementLoaded ? state.roles : const [];
        return ListView(
          children: roles
              .map(
                (role) => ListTile(
                  title: Text(role.roleName),
                  subtitle: Text('${role.permissions.length} modules'),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}

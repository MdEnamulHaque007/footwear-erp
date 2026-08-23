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

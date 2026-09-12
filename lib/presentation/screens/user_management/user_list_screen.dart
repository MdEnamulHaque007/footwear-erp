import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/user_management/user_management_bloc.dart';
import '../../blocs/user_management/user_management_event.dart';
import '../../blocs/user_management/user_management_state.dart';
import '../../widgets/admin_sidebar_widget.dart';
import '../../widgets/role_badge_widget.dart';
import '../../widgets/user_status_widget.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      drawer: const AdminSidebarWidget(),
      body: BlocBuilder<UserManagementBloc, UserManagementState>(
        builder: (context, state) {
          if (state is UserManagementLoading ||
              state is UserManagementInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is UserManagementError) {
            return Center(child: Text(state.message));
          }
          final users = state is UserManagementLoaded ? state.users : const [];
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(
                  user.displayName.isEmpty ? user.email : user.displayName,
                ),
                subtitle: Text(user.email),
                leading: RoleBadgeWidget(role: user.role),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserStatusWidget(active: user.isActive),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => context.read<UserManagementBloc>().add(
                        DeleteUser(user.uid),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

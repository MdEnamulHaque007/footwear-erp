import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/user_entity.dart';
import '../../blocs/user_management/user_management_bloc.dart';
import '../../blocs/user_management/user_management_event.dart';
import '../../blocs/user_management/user_management_state.dart';
import '../../routes/route_constants.dart';
import '../../widgets/role_badge_widget.dart';
import '../../widgets/user_status_widget.dart';

/// Read-only view of one user profile plus their permissions.
class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.uid, this.initialUser});
  final String uid;
  final UserEntity? initialUser;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy hh:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserManagementBloc>().add(
        LoadUserDetail(widget.uid, initialUser: widget.initialUser),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go(RouteConstants.adminUsers);
            }
          },
        ),
        actions: [
          BlocBuilder<UserManagementBloc, UserManagementState>(
            builder: (context, state) => IconButton(
              tooltip: 'Edit User',
              icon: const Icon(Icons.edit),
              onPressed: state is UserDetailLoaded
                  ? () => context.push(
                      '${RouteConstants.adminUsersEdit}/${state.user.uid}',
                      extra: state.user,
                    )
                  : null,
            ),
          ),
        ],
      ),
      body: BlocBuilder<UserManagementBloc, UserManagementState>(
        builder: (context, state) {
          if (state is UserDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is UserManagementError) {
            return Center(child: Text(state.message));
          }
          if (state is! UserDetailLoaded) {
            return const SizedBox.shrink();
          }
          return _detail(state.user);
        },
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 160, child: Text(label)),
        Expanded(child: Text(value)),
      ],
    ),
  );

  Widget _detail(UserEntity user) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _sectionTitle('User Information'),
      _row('Display Name', user.displayLabel),
      _row('Email', user.email.isEmpty ? '-' : user.email),
      _row('UID', user.uid.isEmpty ? '-' : user.uid),
      _row('Photo', user.photoUrl ?? '-'),
      const SizedBox(height: 16),

      _sectionTitle('Role & Permissions'),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 160, child: Text('Role')),
            RoleBadgeWidget(role: user.role),
          ],
        ),
      ),
      if (user.isAdmin)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Admins implicitly hold every permission.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        )
      else
        ..._permissionRows(user),
      const SizedBox(height: 16),

      _sectionTitle('Status'),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 160, child: Text('Status')),
            UserStatusWidget(active: user.isActive),
          ],
        ),
      ),
      _row('Email Verified', user.isEmailVerified ? 'Yes' : 'No'),
      _row(
        'Created At',
        user.createdAt == null ? '-' : _dateFormat.format(user.createdAt!),
      ),
      _row(
        'Last Login',
        user.lastLogin == null ? '-' : _dateTimeFormat.format(user.lastLogin!),
      ),
      const SizedBox(height: 24),

      Wrap(
        spacing: 12,
        children: [
          FilledButton.icon(
            onPressed: () => context.push(
              '${RouteConstants.adminUsersEdit}/${user.uid}',
              extra: user,
            ),
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
          OutlinedButton.icon(
            onPressed: () => context.go(RouteConstants.adminUsers),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
        ],
      ),
    ],
  );

  /// One row per module the user has any permission on.
  List<Widget> _permissionRows(UserEntity user) {
    const empty = Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text('No explicit permissions granted.'),
    );
    final permissions = user.permissions;
    if (permissions == null || permissions.isEmpty) return const [empty];
    final rows = <Widget>[];
    for (final module in AppConstants.permissionModules) {
      final actions = permissions[module];
      if (actions == null) continue;
      final granted = AppConstants.permissionActions
          .where((action) => actions[action] == true)
          .toList();
      if (granted.isEmpty) continue;
      rows.add(_row(module, granted.join(', ')));
    }
    return rows.isEmpty ? const [empty] : rows;
  }
}

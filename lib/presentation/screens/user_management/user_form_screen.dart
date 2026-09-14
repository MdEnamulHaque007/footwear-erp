import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/user_entity.dart';
import '../../blocs/user_management/user_management_bloc.dart';
import '../../blocs/user_management/user_management_event.dart';
import '../../blocs/user_management/user_management_state.dart';
import '../../routes/route_constants.dart';
import '../../widgets/permission_checkbox_widget.dart';

/// Create / edit a user profile.
///
/// Account creation itself happens in Firebase Auth (the repository has no
/// create method here), so in create mode the screen states that; edit mode
/// writes role, status and permissions through the transactional `UpdateUser`.
class UserFormScreen extends StatefulWidget {
  const UserFormScreen({super.key, this.uid, this.initialUser});
  final String? uid;
  final UserEntity? initialUser;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  late String _role;
  late bool _isActive;
  final Map<String, Map<String, bool>> _permissions = {};
  bool _submitting = false;

  bool get _isEdit => (widget.uid ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    final user = widget.initialUser;
    _nameController.text = user?.displayName ?? '';
    _emailController.text = user?.email ?? '';
    _role = user?.role ?? AppConstants.roleViewer;
    _isActive = user?.isActive ?? true;
    // Seed every module × action slot so the grid renders consistently.
    for (final module in AppConstants.permissionModules) {
      final actions = user?.permissions?[module];
      _permissions[module] = {
        for (final action in AppConstants.permissionActions)
          action: actions?[action] ?? false,
      };
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final uid = widget.uid;
    if (uid == null || uid.isEmpty) return;
    setState(() => _submitting = true);
    final existing = widget.initialUser;
    final updated =
        (existing ??
                UserEntity(
                  uid: uid,
                  email: _emailController.text.trim(),
                  displayName: _nameController.text.trim(),
                  role: _role,
                  isEmailVerified: false,
                  isActive: _isActive,
                ))
            .copyWith(
              displayName: _nameController.text.trim(),
              role: _role,
              isActive: _isActive,
              permissions: _prunedPermissions(),
            );
    context.read<UserManagementBloc>().add(UpdateUser(updated));
  }

  /// Drops the all-false action entries so the stored map only holds grants.
  Map<String, Map<String, bool>>? _prunedPermissions() {
    final pruned = <String, Map<String, bool>>{};
    for (final entry in _permissions.entries) {
      final granted = <String, bool>{};
      for (final action in entry.value.entries) {
        if (action.value) granted[action.key] = true;
      }
      if (granted.isNotEmpty) pruned[entry.key] = granted;
    }
    return pruned.isEmpty ? null : pruned;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit User' : 'New User'),
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
      ),
      body: BlocConsumer<UserManagementBloc, UserManagementState>(
        listenWhen: (previous, current) =>
            current is UserManagementSuccess ||
            (current is UserManagementError &&
                previous is UserManagementLoading),
        listener: (context, state) {
          if (state is UserManagementSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            if (mounted) context.pop();
            return;
          }
          if (state is UserManagementError) {
            setState(() => _submitting = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: _formFields(),
          ),
        ),
      ),
    );
  }

  List<Widget> _formFields() => [
    if (!_isEdit)
      const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Text(
          'New accounts are created through Firebase Authentication. '
          'Sign-up creates a viewer profile, which an admin can then edit here.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Display Name',
        border: OutlineInputBorder(),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) =>
          (value ?? '').trim().isEmpty ? 'Display Name is required' : null,
    ),
    const SizedBox(height: 16),
    TextFormField(
      controller: _emailController,
      // Email is the Auth identity; it cannot be changed from this screen.
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
        helperText: 'Email is managed by Firebase Authentication',
      ),
      validator: (value) =>
          (value ?? '').trim().isEmpty ? 'Email is required' : null,
    ),
    const SizedBox(height: 16),
    DropdownButtonFormField<String>(
      initialValue: _safeRole(),
      decoration: const InputDecoration(
        labelText: 'Role',
        border: OutlineInputBorder(),
      ),
      items: AppConstants.assignableRoles
          .map(
            (role) => DropdownMenuItem(
              value: role,
              child: Text(_roleLabel(role)),
            ),
          )
          .toList(),
      onChanged: _submitting
          ? null
          : (value) => setState(() => _role = value ?? _role),
    ),
    const SizedBox(height: 8),
    SwitchListTile(
      value: _isActive,
      onChanged: _submitting
          ? null
          : (value) => setState(() => _isActive = value),
      title: const Text('Active'),
      subtitle: const Text('Inactive users cannot sign in'),
      contentPadding: EdgeInsets.zero,
    ),
    const Divider(height: 32),
    Text(
      'Permissions',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    ),
    if (_role == AppConstants.roleAdmin)
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Admins implicitly hold every permission; these toggles are ignored.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    ..._permissionGrid(),
    const SizedBox(height: 24),
    FilledButton.icon(
      onPressed: _submitting || !_isEdit ? null : _save,
      icon: _submitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save),
      label: Text(_submitting ? 'Saving...' : 'Save'),
    ),
  ];

  /// The role dropdown crashes if its value is not among the items, so an
  /// unknown role falls back to viewer.
  String _safeRole() => AppConstants.assignableRoles.contains(_role)
      ? _role
      : AppConstants.roleViewer;

  static String _roleLabel(String role) =>
      role.isEmpty ? role : '${role[0].toUpperCase()}${role.substring(1)}';

  List<Widget> _permissionGrid() {
    final widgets = <Widget>[];
    for (final module in AppConstants.permissionModules) {
      final actions = _permissions[module];
      if (actions == null) continue;
      widgets.add(
        ExpansionTile(
          title: Text(_moduleLabel(module)),
          initiallyExpanded: actions.values.any((granted) => granted),
          children: [
            for (final action in AppConstants.permissionActions)
              PermissionCheckboxWidget(
                label: _actionLabel(action),
                value: actions[action] ?? false,
                onChanged: _role == AppConstants.roleAdmin || _submitting
                    ? (_) {}
                    : (value) => setState(() => actions[action] = value),
              ),
          ],
        ),
      );
    }
    return widgets;
  }

  static String _moduleLabel(String module) => module
      .split('_')
      .map(_capitalize)
      .join(' ');

  static String _actionLabel(String action) => _capitalize(action);

  static String _capitalize(String value) => value.isEmpty
      ? value
      : '${value[0].toUpperCase()}${value.substring(1)}';
}

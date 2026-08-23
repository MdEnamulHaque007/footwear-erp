import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators/auth_validator.dart';
import '../../blocs/role_management/role_management_bloc.dart';
import '../../blocs/role_management/role_management_event.dart';

class RoleCreateScreen extends StatefulWidget {
  const RoleCreateScreen({super.key});
  @override
  State<RoleCreateScreen> createState() => _RoleCreateScreenState();
}

class _RoleCreateScreenState extends State<RoleCreateScreen> {
  final name = TextEditingController();
  final permissions = <String, Map<String, bool>>{};
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create role')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Role name'),
        ),
        ...AppConstants.permissionModules.map(
          (module) => CheckboxListTile(
            title: Text(module),
            value: permissions[module]?[AppConstants.permissionView] ?? false,
            onChanged: (value) => setState(
              () => permissions[module] = {
                AppConstants.permissionView: value ?? false,
              },
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (AuthValidator.validateName(name.text) == null) {
              context.read<RoleManagementBloc>().add(
                CreateRole(name.text, permissions),
              );
            }
          },
          child: const Text('Create role'),
        ),
      ],
    ),
  );
}

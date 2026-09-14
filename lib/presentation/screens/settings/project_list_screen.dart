import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/color_palette.dart';
import '../../../domain/entities/settings/business_settings_entity.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';
import '../../widgets/app_drawer.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final _projectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SettingsBloc>().add(const LoadBusinessSettings());
      }
    });
  }

  @override
  void dispose() {
    _projectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: const AppDrawer(),
    appBar: AppBar(
      leadingWidth: 96,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/settings'),
          ),
          Builder(
            builder: (drawerContext) => IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(drawerContext).openDrawer(),
            ),
          ),
        ],
      ),
      title: const Text('Project List'),
    ),
    body: BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated || !authState.user.isAdmin) {
          return const _AdminOnlyMessage();
        }
        return BlocConsumer<SettingsBloc, SettingsState>(
          listener: (context, state) {
            if (state is SettingsSaved || state is SettingsError) {
              final message = state is SettingsSaved
                  ? state.message
                  : (state as SettingsError).message;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
          },
          builder: (context, state) {
            if (state is SettingsLoading || state is SettingsInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SettingsError) return _retry();
            if (state is! BusinessSettingsLoaded) {
              return const SizedBox.shrink();
            }
            return _content(state.entity);
          },
        );
      },
    ),
  );

  Widget _retry() => Center(
    child: FilledButton.icon(
      onPressed: () =>
          context.read<SettingsBloc>().add(const LoadBusinessSettings()),
      icon: const Icon(Icons.refresh),
      label: const Text('Try again'),
    ),
  );

  Widget _content(BusinessSettingsEntity settings) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
    children: [
      Text(
        'PROJECT MASTER',
        style: const TextStyle(
          color: ColorPalette.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _projectController,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _add(settings),
                  decoration: const InputDecoration(
                    labelText: 'New project name',
                    prefixIcon: Icon(Icons.folder_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                tooltip: 'Add project',
                onPressed: () => _add(settings),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (settings.projectList.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No projects added yet.')),
          ),
        )
      else
        Card(
          child: Column(
            children: [
              for (
                var index = 0;
                index < settings.projectList.length;
                index++
              ) ...[
                ListTile(
                  leading: const Icon(
                    Icons.folder_outlined,
                    color: ColorPalette.primary,
                  ),
                  title: Text(settings.projectList[index]),
                  trailing: IconButton(
                    tooltip: 'Delete project',
                    icon: const Icon(Icons.delete_outline),
                    color: ColorPalette.error,
                    onPressed: () =>
                        _confirmDelete(settings, settings.projectList[index]),
                  ),
                ),
                if (index < settings.projectList.length - 1)
                  const Divider(height: 1),
              ],
            ],
          ),
        ),
    ],
  );

  void _add(BusinessSettingsEntity settings) {
    final project = _projectController.text.trim();
    if (project.isEmpty) {
      _message('Enter a project name first.');
      return;
    }
    final exists = settings.projectList.any(
      (item) => item.toLowerCase() == project.toLowerCase(),
    );
    if (exists) {
      _message('This project is already in the list.');
      return;
    }
    context.read<SettingsBloc>().add(
      UpdateProjectList([...settings.projectList, project]),
    );
    _projectController.clear();
  }

  Future<void> _confirmDelete(
    BusinessSettingsEntity settings,
    String project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove project?'),
        content: Text('Remove "$project" from the project list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ColorPalette.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<SettingsBloc>().add(
      UpdateProjectList(
        settings.projectList.where((item) => item != project).toList(),
      ),
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AdminOnlyMessage extends StatelessWidget {
  const _AdminOnlyMessage();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Only administrators can manage projects.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

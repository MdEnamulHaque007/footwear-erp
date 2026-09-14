import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/user_entity.dart';
import '../../blocs/user_management/user_management_bloc.dart';
import '../../blocs/user_management/user_management_event.dart';
import '../../blocs/user_management/user_management_state.dart';
import '../../routes/route_constants.dart';
import '../../widgets/role_badge_widget.dart';
import '../../widgets/user_status_widget.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  final _searchController = TextEditingController();
  final _verticalScroll = ScrollController();
  final _horizontalScroll = ScrollController();
  bool _searching = false;

  /// Guards against firing a second page fetch while one is in flight.
  bool _loadingMore = false;

  /// Set when a page fetch fails, so the scroll trigger stays disarmed until
  /// the user refreshes.
  bool _loadMoreFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserManagementBloc>().add(LoadUsers());
    });
    _verticalScroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _verticalScroll.removeListener(_onScroll);
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadMoreFailed) return;
    if (!_verticalScroll.hasClients) return;
    final position = _verticalScroll.position;
    if (position.pixels < position.maxScrollExtent - 200) return;
    if (_loadingMore) return;
    final state = context.read<UserManagementBloc>().state;
    final hasMore = switch (state) {
      UserManagementLoaded(:final hasMore) => hasMore,
      _ => false,
    };
    if (!hasMore) return;
    _loadingMore = true;
    context.read<UserManagementBloc>().add(LoadMoreUsers());
  }

  Future<void> _delete(UserEntity user) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${user.displayLabel}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<UserManagementBloc>().add(DeleteUser(user.uid));
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search name, email or role.',
                  border: InputBorder.none,
                ),
                onChanged: (value) => context.read<UserManagementBloc>().add(
                  value.trim().isEmpty
                      ? ClearSearchUsers()
                      : SearchUsers(value),
                ),
              )
            : const Text('User Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go(RouteConstants.dashboard);
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: _searching ? 'Close search' : 'Search',
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _searchController.clear();
                  context.read<UserManagementBloc>().add(ClearSearchUsers());
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _loadMoreFailed = false;
              context.read<UserManagementBloc>().add(RefreshUsers());
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New User',
            onPressed: () => context.push(RouteConstants.adminUsersNew),
          ),
        ],
      ),
      body: BlocConsumer<UserManagementBloc, UserManagementState>(
        listener: (context, state) {
          final message = switch (state) {
            UserManagementSuccess(:final message) => message,
            UserManagementError(:final message) => message,
            _ => null,
          };
          if (message == null) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (context, state) {
          if (state is UserManagementLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = switch (state) {
            UserManagementLoaded(:final users) => users,
            _ => const <UserEntity>[],
          };
          if (state is UserManagementError) {
            _loadingMore = false;
            _loadMoreFailed = true;
            if (rows.isNotEmpty) return _buildTable(rows, hasMore: false);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      _loadMoreFailed = false;
                      context.read<UserManagementBloc>().add(LoadUsers());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is UserManagementLoaded) {
            _loadingMore = false;
            _loadMoreFailed = false;
            return _buildTable(
              rows,
              hasMore: state.hasMore,
              loadingMore: state is UserManagementLoadingMore,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Excel-style table: horizontal + vertical scroll with dual scrollbars.
  Widget _buildTable(
    List<UserEntity> users, {
    bool hasMore = false,
    bool loadingMore = false,
  }) {
    if (users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            controller: _horizontalScroll,
            thumbVisibility: true,
            notificationPredicate: (notification) => notification.depth == 1,
            child: SingleChildScrollView(
              controller: _verticalScroll,
              padding: const EdgeInsets.all(12),
              child: Scrollbar(
                controller: _verticalScroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalScroll,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 1800),
                    child: DataTable(
                      columnSpacing: 18,
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 64,
                      headingRowColor: WidgetStatePropertyAll(
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      columns: const [
                        DataColumn(label: Text('SL')),
                        DataColumn(label: Text('Display Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Last Login')),
                        DataColumn(label: Text('Created At')),
                        DataColumn(label: Text('Action')),
                      ],
                      rows: _rows(users),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _loadMoreFooter(hasMore: hasMore, loadingMore: loadingMore),
      ],
    );
  }

  List<DataRow> _rows(List<UserEntity> users) => users.asMap().entries.map((
    entry,
  ) {
    final user = entry.value;
    final missing = user.uid.trim().isEmpty;
    return DataRow(
      color: WidgetStatePropertyAll(
        entry.key.isEven ? Colors.grey.shade50 : null,
      ),
      onSelectChanged: missing ? null : (_) => _openDetail(user),
      cells: [
        DataCell(
          GestureDetector(
            onDoubleTap: () => _openDetail(user),
            child: Text('${entry.key + 1}'),
          ),
        ),
        DataCell(
          GestureDetector(
            onDoubleTap: () => _openDetail(user),
            child: Text(_text(user.displayLabel)),
          ),
        ),
        DataCell(Text(_text(user.email))),
        DataCell(RoleBadgeWidget(role: _text(user.role))),
        DataCell(UserStatusWidget(active: user.isActive)),
        DataCell(Text(_formatDate(user.lastLogin))),
        DataCell(Text(_formatDate(user.createdAt))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'View Details',
                iconSize: 20,
                color: Colors.blue,
                icon: const Icon(Icons.visibility),
                onPressed: missing ? null : () => _openDetail(user),
              ),
              IconButton(
                tooltip: 'Edit User',
                iconSize: 20,
                color: Colors.blue,
                icon: const Icon(Icons.edit),
                onPressed: missing
                    ? null
                    : () => context.push(
                        '${RouteConstants.adminUsersEdit}/${user.uid}',
                        extra: user,
                      ),
              ),
              IconButton(
                tooltip: 'Delete User',
                iconSize: 20,
                color: Colors.red,
                icon: const Icon(Icons.delete),
                onPressed: missing ? null : () => _delete(user),
              ),
            ],
          ),
        ),
      ],
    );
  }).toList();

  void _openDetail(UserEntity user) {
    if (user.uid.trim().isEmpty) return;
    context.push('${RouteConstants.adminUsersDetail}/${user.uid}', extra: user);
  }

  /// Footer under the table: a spinner during a fetch, a hint when more rows
  /// remain, nothing once exhausted.
  Widget _loadMoreFooter({required bool hasMore, required bool loadingMore}) {
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading more...'),
          ],
        ),
      );
    }
    if (hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Scroll down to load more',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () {
                if (_loadingMore) return;
                _loadingMore = true;
                context.read<UserManagementBloc>().add(LoadMoreUsers());
              },
              child: const Text('Load More'),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  static String _text(Object? value, {String fallback = '-'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String _formatDate(DateTime? value) =>
      value == null ? '-' : _dateFormat.format(value);
}

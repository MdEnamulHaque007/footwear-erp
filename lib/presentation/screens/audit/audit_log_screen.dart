import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/color_palette.dart';
import '../../../data/repositories/activity/activity_log_repository.dart';
import '../../../domain/entities/activity/activity_log_entry.dart';
import '../../routes/route_constants.dart';

const activityModuleLabels = <String, String>{
  'master_lc': 'Master LC',
  'purchase_order': 'Purchase Order',
  'cutting': 'Cutting',
  'sewing': 'Sewing',
  'production': 'Lasting / Production',
  'issue': 'FG Issue',
  'export': 'Export',
  'user_management': 'Users',
  'role_management': 'Roles',
  'settings': 'Settings',
  'dashboard': 'Dashboard',
  'reports': 'Reports',
};

/// Admin-only activity history; existing /audit-log links remain valid.
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key, this.repository});
  final ActivityLogRepository? repository;
  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  late final ActivityLogRepository _repository;
  final _actorController = TextEditingController();
  List<ActivityLogEntry> _entries = [];
  String? _module;
  String? _action;
  DateTimeRange? _dates;
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loading = false;
  bool _hasMore = false;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ActivityLogRepository();
    _load();
  }

  @override
  void dispose() {
    _actorController.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      if (!more) {
        _entries = [];
        _cursor = null;
        _hasMore = false;
      }
    });
    try {
      final dates = _dates;
      final end = dates?.end;
      final page = await _repository.load(
        module: _module,
        action: _action,
        actorUid: _actorController.text.trim(),
        from: dates?.start,
        toExclusive: end == null
            ? null
            : DateTime(end.year, end.month, end.day + 1),
        after: more ? _cursor : null,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _entries = more ? [..._entries, ...page.entries] : page.entries;
        _cursor = page.cursor;
        _hasMore = page.hasMore;
      });
    } on FirebaseException catch (error) {
      if (!mounted || request != _request) return;
      setState(
        () => _error = error.code == 'permission-denied'
            ? 'You do not have permission to view activity logs.'
            : error.code == 'failed-precondition'
            ? 'Activity log indexes are not ready. Deploy the Firestore indexes and try again.'
            : 'Unable to load activity logs. Check your connection and retry.',
      );
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() => _error = 'Unable to load activity logs. Please retry.');
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _selectDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _dates,
    );
    if (picked == null || !mounted) return;
    setState(() => _dates = picked);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        backgroundColor: ColorPalette.auditLog,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Dashboard',
          onPressed: () => context.go(RouteConstants.dashboard),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh activity logs',
            onPressed: _loading ? null : () => _load(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('module-$_module'),
                    initialValue: _module ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Module',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('All modules'),
                      ),
                      ...activityModuleLabels.entries.map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _module = value == '' ? null : value);
                      _load();
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('action-$_action'),
                    initialValue: _action ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Action',
                      border: OutlineInputBorder(),
                    ),
                    items: ['', 'create', 'read', 'update', 'delete']
                        .map(
                          (action) => DropdownMenuItem(
                            value: action,
                            child: Text(
                              action.isEmpty
                                  ? 'All actions'
                                  : action.toUpperCase(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _action = value == '' ? null : value);
                      _load();
                    },
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _actorController,
                    decoration: InputDecoration(
                      labelText: 'User UID (exact match)',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: 'Apply user filter',
                        icon: const Icon(Icons.search),
                        onPressed: () => _load(),
                      ),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _selectDates,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _dates == null
                        ? 'Date range'
                        : '${DateFormat.yMMMd().format(_dates!.start)} – ${DateFormat.yMMMd().format(_dates!.end)}',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _module = null;
                      _action = null;
                      _dates = null;
                      _actorController.clear();
                    });
                    _load();
                  },
                  child: const Text('Clear filters'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Newest first • Write history is recorded on the server; Read history is reported by the app.',
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _load(more: _entries.isNotEmpty),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _entries.isEmpty
                ? Center(
                    child: Text(
                      _loading
                          ? 'Loading activity…'
                          : _error != null
                          ? ''
                          : 'No activities found for these filters.',
                    ),
                  )
                : ListView.separated(
                    itemCount: _entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _activityTile(_entries[index]),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${_entries.length} activities loaded'),
                if (_hasMore) ...[
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: _loading ? null : () => _load(more: true),
                    child: const Text('Load more'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityTile(ActivityLogEntry entry) {
    final icon = switch (entry.action) {
      'create' => Icons.add_circle_outline,
      'update' => Icons.edit_outlined,
      'delete' => Icons.delete_outline,
      _ => Icons.visibility_outlined,
    };
    final date = entry.createdAt;
    return ListTile(
      leading: Icon(icon, color: entry.action == 'delete' ? Colors.red : null),
      title: Text(
        '${entry.action.toUpperCase()} • ${activityModuleLabels[entry.module] ?? entry.module} • ${entry.label}',
      ),
      subtitle: Text(
        '${entry.actorName}\n${date == null ? 'Pending timestamp' : DateFormat('dd MMM yyyy, HH:mm:ss').format(date.toLocal())}${entry.status == 'failure' ? ' • FAILED' : ''}',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showDetails(entry),
    );
  }

  void _showDetails(ActivityLogEntry entry) {
    final data = entry.data;
    final before = data['before'];
    final after = data['after'];
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activity details'),
        content: SizedBox(
          width: 760,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  'Action: ${entry.action.toUpperCase()}\n'
                  'Module: ${activityModuleLabels[entry.module] ?? entry.module}\n'
                  'User: ${entry.actorName}\nUID: ${entry.actorUid}\n'
                  'Email: ${data['actorEmail'] ?? ''}\n'
                  'Time: ${entry.createdAt?.toLocal() ?? ''}\n'
                  'Record: ${data['documentPath'] ?? data['documentId'] ?? ''}\n'
                  'Operation: ${data['operation'] ?? entry.action}\n'
                  'Source: ${data['source'] ?? ''}\nStatus: ${entry.status}\n'
                  'Results: ${data['resultCount'] ?? '—'}\n'
                  'Changed fields: ${(data['changedFields'] as List?)?.join(', ') ?? '—'}',
                ),
                if (before != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Before',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SelectableText(
                    const JsonEncoder.withIndent('  ').convert(before),
                  ),
                ],
                if (after != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'After',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SelectableText(
                    const JsonEncoder.withIndent('  ').convert(after),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

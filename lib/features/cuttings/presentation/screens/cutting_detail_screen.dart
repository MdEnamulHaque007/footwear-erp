import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/cutting_provider.dart';

class CuttingDetailScreen extends ConsumerWidget {
  const CuttingDetailScreen({super.key, required this.docId});

  final String docId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuttingAsync = ref.watch(cuttingDetailProvider(docId));
    final accessAsync = ref.watch(cuttingAccessProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cutting Detail / কাটিং বিস্তারিত'),
        actions: [
          accessAsync.maybeWhen(
            data: (access) => access.canEdit
                ? IconButton(
                    tooltip: 'Edit',
                    onPressed: () async {
                      final cutting =
                          await ref.read(cuttingDetailProvider(docId).future);
                      if (cutting != null && context.mounted) {
                        context.push(
                          '/cuttings/$docId/edit',
                          extra: cutting,
                        );
                      }
                    },
                    icon: const Icon(Icons.edit),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          accessAsync.maybeWhen(
            data: (access) => access.canDelete
                ? IconButton(
                    tooltip: 'Delete',
                    onPressed: () => _delete(context, ref),
                    icon: const Icon(Icons.delete_outline),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: cuttingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
        data: (cutting) {
          if (cutting == null) {
            return const Center(child: Text('Cutting record not found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section(
                context,
                'Cutting Info / কাটিং তথ্য',
                [
                  _item('Date / তারিখ', cutting.formattedDate),
                  _item('V.No / ভাউচার নং', cutting.voucherNo),
                  _item('Factory / কারখানা', cutting.factoryName),
                  _item('PO No / PO নং', cutting.poNo),
                  _item('Article / আর্টিকেল', cutting.article),
                  _item('Color / রং', cutting.color),
                  _item('Quantity / পরিমাণ', cutting.cuttingQuantity.toString()),
                  _item('Entry Person / এন্ট্রি ব্যক্তি',
                      cutting.entryPerson ?? ''),
                ],
              ),
              const SizedBox(height: 16),
              _section(
                context,
                'PO Info / PO তথ্য',
                [
                  _item('Tag No / ট্যাগ নং', cutting.tagNo),
                  _item('Company / কোম্পানি', cutting.company),
                  _item('Project / প্রজেক্ট', cutting.project),
                  _item('PO Quantity / PO পরিমাণ',
                      cutting.poQuantity.toString()),
                ],
              ),
              const SizedBox(height: 16),
              _section(
                context,
                'System Info / সিস্টেম তথ্য',
                [
                  _item('Source', cutting.source),
                  _item(
                    'Sync Status / সিঙ্ক অবস্থা',
                    cutting.syncStatus,
                    valueWidget: _statusBadge(context, cutting.syncStatus),
                  ),
                  _item(
                    'Created At',
                    DateFormat('dd-MMM-yyyy HH:mm').format(cutting.createdAt),
                  ),
                  _item(
                    'Updated At',
                    DateFormat('dd-MMM-yyyy HH:mm').format(cutting.updatedAt),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _item(
    String label,
    String value, {
    Widget? valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label)),
          const SizedBox(width: 12),
          Expanded(child: valueWidget ?? Text(value)),
        ],
      ),
    );
  }

  Widget _statusBadge(BuildContext context, String status) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(status),
        avatar: Icon(
          status == 'synced' ? Icons.check_circle : Icons.sync_problem,
          size: 18,
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cutting / কাটিং মুছবেন?'),
        content: const Text(
          'This is an admin-only soft-delete action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(cuttingRepositoryProvider).softDelete(docId);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}

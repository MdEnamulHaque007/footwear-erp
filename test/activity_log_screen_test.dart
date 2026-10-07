import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/data/repositories/activity/activity_log_repository.dart';
import 'package:footwear/domain/entities/activity/activity_log_entry.dart';
import 'package:footwear/presentation/screens/audit/audit_log_screen.dart';

class FakeActivityRepository extends ActivityLogRepository {
  final calls = <Map<String, String?>>[];
  bool empty = false;
  bool fail = false;
  @override
  Future<ActivityLogPage> load({
    String? module,
    String? action,
    String? actorUid,
    DateTime? from,
    DateTime? toExclusive,
    after,
  }) async {
    calls.add({'module': module, 'action': action, 'uid': actorUid});
    if (fail) throw StateError('offline');
    return ActivityLogPage(
      entries: empty
          ? []
          : [
              ActivityLogEntry(
                id: 'log',
                data: {
                  'action': 'update',
                  'module': 'cutting',
                  'actorName': 'Enamul',
                  'actorUid': 'u1',
                  'recordLabel': 'C-1',
                  'createdAt': DateTime(2026, 10, 7),
                  'changedFields': ['quantity'],
                  'before': {'quantity': 10},
                  'after': {'quantity': 20},
                },
              ),
            ],
      hasMore: false,
    );
  }
}

void main() {
  testWidgets('activity row opens old and new record details', (tester) async {
    final repo = FakeActivityRepository();
    await tester.pumpWidget(
      MaterialApp(home: AuditLogScreen(repository: repo)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Activity Log'), findsOneWidget);
    await tester.tap(find.text('UPDATE • Cutting • C-1'));
    await tester.pumpAndSettle();
    expect(find.text('Before'), findsOneWidget);
    expect(find.text('After'), findsOneWidget);
    expect(find.textContaining('"quantity": 10'), findsOneWidget);
    expect(find.textContaining('"quantity": 20'), findsOneWidget);
  });
  testWidgets('empty state and refresh work', (tester) async {
    final repo = FakeActivityRepository()..empty = true;
    await tester.pumpWidget(
      MaterialApp(home: AuditLogScreen(repository: repo)),
    );
    await tester.pumpAndSettle();
    expect(find.text('No activities found for these filters.'), findsOneWidget);
    await tester.tap(find.byTooltip('Refresh activity logs'));
    await tester.pumpAndSettle();
    expect(repo.calls, hasLength(2));
  });
  testWidgets('user filter and clear filters reload the query', (tester) async {
    final repo = FakeActivityRepository();
    await tester.pumpWidget(
      MaterialApp(home: AuditLogScreen(repository: repo)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'u1');
    await tester.tap(find.byTooltip('Apply user filter'));
    await tester.pumpAndSettle();
    expect(repo.calls.last['uid'], 'u1');
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(repo.calls.last['uid'], '');
  });
  testWidgets('load error shows retry and recovers', (tester) async {
    final repo = FakeActivityRepository()..fail = true;
    await tester.pumpWidget(
      MaterialApp(home: AuditLogScreen(repository: repo)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('UPDATE • Cutting • C-1'), findsOneWidget);
  });
}

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/core/services/activity/activity_log_service.dart';

void main() {
  final actor = {'uid': 'u1', 'name': 'Enamul', 'email': 'a@example.com'};
  test(
    'successful reads retain result and authenticated attribution',
    () async {
      final logs = <Map<String, dynamic>>[];
      final service = ActivityLogService(
        actor: actor,
        writer: (data) async => logs.add(data),
      );
      final result = await service.trackRead(
        module: 'cutting',
        operation: 'byId',
        documentId: 'c1',
        body: () async => const Right<String, int>(10),
      );
      expect(result, const Right<String, int>(10));
      expect(logs.single['actorUid'], 'u1');
      expect(logs.single['documentId'], 'c1');
      expect(logs.single['action'], 'read');
      expect(logs.single['source'], 'app_read');
      expect(logs.single['status'], 'success');
    },
  );
  test(
    'Either failures are labelled without leaking the error payload',
    () async {
      final logs = <Map<String, dynamic>>[];
      final service = ActivityLogService(
        actor: actor,
        writer: (data) async => logs.add(data),
      );
      await service.trackRead(
        module: 'cutting',
        operation: 'getCuttingList',
        body: () async => const Left<String, int>('sensitive error'),
      );
      expect(logs.single['status'], 'failure');
      expect(logs.single.toString(), isNot(contains('sensitive error')));
    },
  );
  test('nested lookups produce one public-operation read log', () async {
    final logs = <Map<String, dynamic>>[];
    final service = ActivityLogService(
      actor: actor,
      writer: (data) async => logs.add(data),
    );
    await service.trackRead(
      module: 'cutting',
      operation: 'list',
      body: () async {
        return service.trackRead(
          module: 'purchase_order',
          operation: 'lookup',
          body: () async => [1, 2],
        );
      },
    );
    expect(logs, hasLength(1));
    expect(logs.single['operation'], 'list');
    expect(logs.single['resultCount'], 2);
  });
  test('independent concurrent operations each get a log', () async {
    final logs = <Map<String, dynamic>>[];
    final service = ActivityLogService(
      actor: actor,
      writer: (data) async => logs.add(data),
    );
    await Future.wait(
      ['one', 'two'].map(
        (operation) => service.trackRead(
          module: 'cutting',
          operation: operation,
          body: () async => 1,
        ),
      ),
    );
    expect(logs, hasLength(2));
  });
  test('logger failure never replaces a successful business read', () async {
    final service = ActivityLogService(
      actor: actor,
      writer: (_) async => throw StateError('offline'),
    );
    expect(
      await service.trackRead(
        module: 'cutting',
        operation: 'list',
        body: () async => 42,
      ),
      42,
    );
  });
  test('thrown business errors propagate after failure is recorded', () async {
    final logs = <Map<String, dynamic>>[];
    final service = ActivityLogService(
      actor: actor,
      writer: (data) async => logs.add(data),
    );
    await expectLater(
      service.trackRead<int>(
        module: 'cutting',
        operation: 'list',
        body: () async => throw StateError('business'),
      ),
      throwsStateError,
    );
    expect(logs.single['status'], 'failure');
  });
}

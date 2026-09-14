import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/domain/entities/po_entity.dart';
import 'package:footwear/domain/repositories/i_po_repository.dart';
import 'package:footwear/domain/usecases/purchase_order/create_po_usecase.dart';
import 'package:footwear/domain/usecases/purchase_order/update_po_usecase.dart';

POEntity _po({String? id, String poNo = 'PO-001', int sl = 0}) => POEntity(
  id: id,
  sl: sl,
  poDate: DateTime(2024, 7, 10),
  tagNo: 'TAG-1',
  company: 'Bata Shoe Company',
  project: 'Bata',
  brand: 'B',
  poNo: poNo,
  entryPerson: 'tester',
  lineItems: const [
    POLineItemEntity(
      article: 'ART-1',
      color: 'RED',
      poQuantity: 100,
      unitPrice: 10,
    ),
  ],
);

/// In-memory stand-in for the counter document + collection-max reconciliation
/// performed by `PORepository._writeWithTransaction` on the create path, plus
/// the global PO No uniqueness gate.
class FakePOStore {
  final List<POEntity> records = [];
  int _counter = 0;

  int _maxStoredSl() => records.isEmpty
      ? 0
      : records.map((r) => r.sl).reduce((a, b) => a > b ? a : b);

  /// Mirrors the repository's atomic allocation:
  ///   lastAssigned = max(counter, maxStoredSl); nextSl = lastAssigned + 1
  int allocateSl() {
    var lastAssigned = _counter;
    final maxStored = _maxStoredSl();
    if (maxStored > lastAssigned) lastAssigned = maxStored;
    final nextSl = lastAssigned + 1;
    _counter = nextSl;
    return nextSl;
  }

  /// What the repository's `getMaxSl()` returns before a create.
  int peekNextSl() {
    var next = _counter;
    final maxStored = _maxStoredSl();
    if (maxStored > next) next = maxStored;
    return next + 1;
  }

  /// Global PO No uniqueness, with self-exclusion on update.
  bool isPoNoUnique(String poNo, {String? excludeId}) =>
      records.every((r) => r.id == excludeId || r.poNo != poNo.trim());

  POEntity create(POEntity item) {
    var created = item.copyWith(id: 'id-${records.length + 1}');
    created = created.copyWith(sl: allocateSl());
    records.add(created);
    return created;
  }
}

/// Records what the use cases hand to the repository.
class _RecordingPORepository implements IPORepository {
  _RecordingPORepository({this.poNoTaken = false});
  final bool poNoTaken;
  POEntity? lastCreated;
  POEntity? lastUpdated;

  @override
  Future<bool> isPoNoUnique(String poNo, {String? excludeId}) async =>
      !poNoTaken;

  @override
  Future<Either<String, void>> createWithTransaction(POEntity item) async {
    lastCreated = item;
    return const Right(null);
  }

  @override
  Future<Either<String, void>> updateWithTransaction(POEntity item) async {
    lastUpdated = item;
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PO Sl. auto-generation (SRS Rule 1)', () {
    test('first PO gets Sl. 1 on an empty collection', () {
      final store = FakePOStore();
      expect(store.peekNextSl(), 1);
      expect(store.create(_po()).sl, 1);
    });

    test('Sl. auto-increments 1 -> 2 -> 3', () {
      final store = FakePOStore();
      expect(store.create(_po(poNo: 'PO-1')).sl, 1);
      expect(store.create(_po(poNo: 'PO-2')).sl, 2);
      expect(store.create(_po(poNo: 'PO-3')).sl, 3);
    });

    test('no duplicate Sl. across many sequential creates', () {
      final store = FakePOStore();
      for (var i = 0; i < 50; i++) {
        store.create(_po(poNo: 'PO-$i'));
      }
      final serials = store.records.map((r) => r.sl).toList();
      expect(serials.toSet(), hasLength(50), reason: 'Sl. must be unique');
      expect(serials, List.generate(50, (i) => i + 1));
    });

    test('reconciles with legacy rows that predate the counter', () {
      final store = FakePOStore();
      store.records.add(_po(poNo: 'LEGACY', sl: 900));
      expect(store.peekNextSl(), 901);
      expect(store.create(_po(poNo: 'PO-NEW')).sl, 901);
    });

    test('multiple POs can share a tag (one tag -> many PO numbers)', () {
      final store = FakePOStore();
      final a = store.create(_po(poNo: 'PO-A'));
      final b = store.create(_po(poNo: 'PO-B'));
      expect(a.tagNo, b.tagNo);
      expect([a.sl, b.sl], [1, 2]);
    });
  });

  group('PO No global uniqueness', () {
    test('a fresh PO No is accepted', () {
      final store = FakePOStore();
      store.create(_po(poNo: 'PO-001'));
      expect(store.isPoNoUnique('PO-002'), isTrue);
    });

    test('a duplicate PO No is rejected', () {
      final store = FakePOStore();
      store.create(_po(poNo: 'PO-001'));
      expect(store.isPoNoUnique('PO-001'), isFalse);
    });

    test('self-exclusion lets a PO keep its own number on update', () {
      final store = FakePOStore();
      final created = store.create(_po(poNo: 'PO-001'));
      expect(store.isPoNoUnique('PO-001', excludeId: created.id), isTrue);
    });

    test('trimmed comparison treats surrounding spaces as the same number', () {
      final store = FakePOStore();
      store.create(_po(poNo: 'PO-001'));
      expect(store.isPoNoUnique('  PO-001  '), isFalse);
    });
  });

  group('CreatePOUseCase', () {
    test('discards a caller-supplied Sl. (the epoch bug)', () async {
      final repository = _RecordingPORepository();
      await CreatePOUseCase(repository)(
        _po(sl: DateTime.now().millisecondsSinceEpoch),
      );
      expect(repository.lastCreated!.sl, 0, reason: 'must be the sentinel');
    });

    test('rejects a duplicate PO No with a friendly message', () async {
      final repository = _RecordingPORepository(poNoTaken: true);
      final result = await CreatePOUseCase(repository)(_po());
      expect(result.isLeft(), isTrue);
      expect(result.fold((e) => e, (_) => ''), 'PO No PO-001 already exists');
      expect(repository.lastCreated, isNull);
    });

    test('rejects an empty PO No', () async {
      final repository = _RecordingPORepository();
      final result = await CreatePOUseCase(repository)(_po(poNo: '   '));
      expect(result.fold((e) => e, (_) => ''), 'PO No is required');
    });
  });

  group('UpdatePOUseCase', () {
    test('rejects a duplicate PO No when editing another record', () async {
      final repository = _RecordingPORepository(poNoTaken: true);
      final result = await UpdatePOUseCase(repository)(
        _po(id: 'po-9', sl: 9),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.lastUpdated, isNull);
    });

    test('allows saving when the number is unique', () async {
      final repository = _RecordingPORepository();
      final result = await UpdatePOUseCase(repository)(_po(id: 'po-9', sl: 9));
      expect(result.isRight(), isTrue);
      expect(repository.lastUpdated!.id, 'po-9');
    });
  });
}


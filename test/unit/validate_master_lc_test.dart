/// ============================================================================
/// ফাইল: test/unit/validate_master_lc_test.dart
/// স্তর: Test | মডিউল: Master LC
/// উদ্দেশ্য: Validate Master Lc Test অংশের প্রত্যাশিত আচরণ স্বয়ংক্রিয়ভাবে যাচাই করে এবং regression প্রতিরোধ করে।
/// প্রধান অংশ: FakeMasterLCStore, _RecordingRepository
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/core/constants/app_constants.dart';
import 'package:footwear/domain/entities/master_lc_entity.dart';
import 'package:footwear/domain/repositories/i_master_lc_repository.dart';
import 'package:footwear/domain/usecases/master_lc/create_master_lc_usecase.dart';

MasterLCEntity _entity({int sl = 0, String tagNo = 'TAG-1'}) => MasterLCEntity(
  sl: sl,
  masterLcDate: DateTime(2024, 7, 10),
  tagNo: tagNo,
  project: 'Bata',
  company: 'Bata Shoe Company',
  masterLcQuantity: 1000,
  masterLcValue: 50000,
);

/// In-memory stand-in for the counter document + collection max reconciliation
/// performed by `MasterLCRepository._writeWithTransaction` on the create path.
class FakeMasterLCStore {
  final List<MasterLCEntity> records = [];
  int _counter = 0;

  /// Mirrors the repository's atomic allocation:
  ///   lastAssigned = max(counter, maxStoredSl); nextSl = lastAssigned + 1
  int allocateSl() {
    var lastAssigned = _counter;
    final maxStored = records.isEmpty
        ? 0
        : records.map((r) => r.sl).reduce((a, b) => a > b ? a : b);
    if (maxStored > lastAssigned) lastAssigned = maxStored;
    final nextSl = lastAssigned + 1;
    _counter = nextSl;
    return nextSl;
  }

  MasterLCEntity create(MasterLCEntity item) {
    final created = item.copyWith(sl: allocateSl());
    records.add(created);
    return created;
  }

  /// What the repository's `getMaxSl()` returns before a create.
  int peekNextSl() {
    var next = _counter;
    final maxStored = records.isEmpty
        ? 0
        : records.map((r) => r.sl).reduce((a, b) => a > b ? a : b);
    if (maxStored > next) next = maxStored;
    return next + 1;
  }
}

void main() {
  group('Master LC Sl. auto-generation (SRS Rule 1)', () {
    test('first record gets Sl. 1 on an empty collection', () {
      final store = FakeMasterLCStore();
      expect(store.peekNextSl(), 1);
      final created = store.create(_entity());
      expect(created.sl, 1);
    });

    test('Sl. auto-increments 1 → 2 → 3', () {
      final store = FakeMasterLCStore();
      expect(store.create(_entity(tagNo: 'TAG-1')).sl, 1);
      expect(store.create(_entity(tagNo: 'TAG-2')).sl, 2);
      expect(store.create(_entity(tagNo: 'TAG-3')).sl, 3);
    });

    test('no duplicate Sl. across many sequential creates', () {
      final store = FakeMasterLCStore();
      for (var i = 0; i < 50; i++) {
        store.create(_entity(tagNo: 'TAG-$i'));
      }
      final serials = store.records.map((r) => r.sl).toList();
      expect(serials.toSet(), hasLength(50), reason: 'Sl. must be unique');
      expect(serials, List.generate(50, (i) => i + 1));
    });

    test('reconciles with pre-existing records that predate the counter', () {
      final store = FakeMasterLCStore();
      // Simulate legacy rows written with a large Sl. before the counter existed.
      store.records.add(_entity(sl: 4200, tagNo: 'LEGACY'));
      expect(store.peekNextSl(), 4201);
      expect(store.create(_entity(tagNo: 'TAG-NEW')).sl, 4201);
    });

    test('Sl. is independent of the tag and PO headroom', () {
      final store = FakeMasterLCStore();
      final first = store.create(_entity(tagNo: 'SAME'));
      final second = store.create(_entity(tagNo: 'SAME'));
      expect(first.sl, 1);
      expect(second.sl, 2);
    });
  });

  group('CreateMasterLCUseCase normalises the Sl.', () {
    test('caller-supplied Sl. is discarded before persistence', () {
      final repository = _RecordingRepository();
      final useCase = CreateMasterLCUseCase(repository);

      // Caller passes a bogus epoch-style Sl., exactly the bug being fixed.
      useCase(_entity(sl: DateTime.now().millisecondsSinceEpoch));

      expect(repository.lastCreated!.sl, 0, reason: 'must be the sentinel');
    });

    test('a normal Sl. is also normalised to the sentinel', () {
      final repository = _RecordingRepository();
      CreateMasterLCUseCase(repository)(_entity(sl: 7));
      expect(repository.lastCreated!.sl, 0);
    });
  });

  group('app_constants wiring', () {
    test('counter collection constant is defined for the sequence docs', () {
      expect(AppConstants.collectionCounters, '_counters');
    });
  });
}

/// Captures the entity the use case hands to the repository.
class _RecordingRepository implements IMasterLCRepository {
  MasterLCEntity? lastCreated;

  @override
  Future<Either<String, void>> createWithTransaction(
    MasterLCEntity item,
  ) async {
    lastCreated = item;
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/data/models/purchase_order/po_model.dart';
import 'package:footwear/data/models/sewing/sewing_model.dart';
import 'package:footwear/domain/entities/sewing_entity.dart';
import 'package:footwear/domain/repositories/i_sewing_repository.dart';
import 'package:footwear/domain/usecases/sewing/validate_sewing_quantity_usecase.dart';

/// Stub repository exposing the two cumulative reads the validator depends on.
class FakeSewingRepository implements ISewingRepository {
  FakeSewingRepository({this.cutting = 0, this.sewing = 0});

  /// Cumulative Cutting for the PO line (already date-filtered by the repo).
  int cutting;

  /// Cumulative Sewing for the PO line (self-excluded by the repo).
  int sewing;

  /// Records the date the validator asked the Cutting side for.
  DateTime? requestedUpToDate;

  String? requestedExcludeId;

  @override
  Future<int> getCumulativeCuttingQty({
    required String poNo,
    required String article,
    required String color,
    required DateTime upToDate,
    String? excludingId,
  }) async {
    requestedUpToDate = upToDate;
    return cutting;
  }

  @override
  Future<int> getCumulativeSewingQty({
    required String poNo,
    required String article,
    required String color,
    String? excludeId,
  }) async {
    requestedExcludeId = excludeId;
    return sewing;
  }

  @override
  Future<Either<String, List<SewingModel>>> getSewingList({
    int page = 0,
    int limit = 20,
  }) async => const Right([]);

  @override
  Future<Either<String, List<SewingModel>>> byPoTag(String poTagNo) async =>
      const Right([]);

  @override
  Future<Either<String, SewingModel?>> byId(String id) async =>
      const Right(null);

  @override
  Future<Either<String, List<SewingModel>>> byLine({
    required String poNo,
    required String article,
    required String color,
  }) async => const Right([]);

  @override
  Future<Either<String, List<String>>> getPONoList() async => const Right([]);

  @override
  Future<Either<String, List<String>>> getCuttingEntryPONoList() async =>
      const Right([]);

  @override
  Future<Either<String, List<POModel>>> getPOListForDropdown() async =>
      const Right([]);

  @override
  Future<Either<String, POModel?>> getPOByNo(String poNo) async =>
      const Right(null);

  @override
  Future<Either<String, void>> createWithTransaction(SewingEntity item) async =>
      const Right(null);

  @override
  Future<Either<String, void>> updateWithTransaction(SewingEntity item) async =>
      const Right(null);

  @override
  Future<Either<String, void>> createSewing(SewingEntity item) async =>
      const Right(null);

  @override
  Future<Either<String, void>> update(SewingEntity item) async =>
      const Right(null);

  @override
  Future<Either<String, void>> delete(String id) async => const Right(null);

  @override
  Future<int> getCumulativeSewingQuantity({
    required String poTagNo,
    required DateTime upToDate,
  }) async => sewing;
}

void main() {
  group('ValidateSewingQuantityUseCase', () {
    late FakeSewingRepository repo;
    late ValidateSewingQuantityUseCase useCase;

    setUp(() {
      repo = FakeSewingRepository();
      useCase = ValidateSewingQuantityUseCase(repo);
    });

    test('accepts a quantity within the available cutting quantity', () async {
      repo.cutting = 500;
      repo.sewing = 0;
      final result = await useCase(
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        candidateQuantity: 300,
        sewingDate: DateTime(2024, 7, 10),
      );
      expect(result, isNull);
    });

    test('rejects zero or negative quantity', () async {
      repo.cutting = 500;
      final result = await useCase(
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        candidateQuantity: 0,
      );
      expect(result, 'Quantity must be greater than zero');
    });

    test(
      'rejects a quantity exceeding the remaining cutting balance',
      () async {
        repo.cutting = 500;
        repo.sewing = 300;
        final result = await useCase(
          poNo: 'PO-001',
          article: 'ART-1',
          color: 'RED',
          candidateQuantity: 250,
          sewingDate: DateTime(2024, 7, 10),
        );
        expect(
          result,
          contains('Sewing quantity exceeds available cutting quantity'),
        );
        expect(result, contains('available: 200'));
      },
    );

    test('accepts a larger quantity once later cutting is available', () async {
      // 10 July: 500 cut, 12 July: 300 more → 800 available for a 12 July sewing.
      repo.cutting = 800;
      repo.sewing = 0;
      final result = await useCase(
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        candidateQuantity: 700,
        sewingDate: DateTime(2024, 7, 12),
      );
      expect(result, isNull);
    });

    test('passes the sewing date through as the cutting cut-off', () async {
      final sewingDate = DateTime(2024, 7, 10);
      await useCase(
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        candidateQuantity: 10,
        sewingDate: sewingDate,
      );
      expect(repo.requestedUpToDate, sewingDate);
    });

    test('self-excludes the edited entry when updating', () async {
      await useCase.validateUpdate(
        sewingId: 'sew-1',
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        candidateQuantity: 10,
        sewingDate: DateTime(2024, 7, 10),
      );
      expect(repo.requestedExcludeId, 'sew-1');
    });

    test('skips the availability lookup when no PO line is selected', () async {
      final available = await useCase.availability(
        poNo: '',
        article: '',
        color: '',
      );
      expect(available, 0);
    });

    test('availability is cutting minus sewing', () async {
      repo.cutting = 900;
      repo.sewing = 250;
      final available = await useCase.availability(
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        sewingDate: DateTime(2024, 7, 12),
      );
      expect(available, 650);
    });
  });
}

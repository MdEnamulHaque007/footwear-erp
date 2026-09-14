import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/domain/repositories/i_production_repository.dart';
import 'package:footwear/domain/repositories/i_sewing_repository.dart';
import 'package:footwear/domain/usecases/production/validate_production_quantity_usecase.dart';

/// Minimal sewing stub: only the cumulative reads used by the validator matter.
class _FakeSewingRepository implements ISewingRepository {
  _FakeSewingRepository(this.tagQty, this.lineQty);
  final int tagQty;
  final int lineQty;
  DateTime? requestedUpToDate;

  @override
  Future<int> getCumulativeSewingQuantity({
    required String poTagNo,
    required DateTime upToDate,
  }) async {
    requestedUpToDate = upToDate;
    return tagQty;
  }

  @override
  Future<int> getCumulativeSewingQty({
    required String poNo,
    required String article,
    required String color,
    String? excludeId,
  }) async => lineQty;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Minimal production stub exposing the line-filtered cumulative read.
class _FakeProductionRepository implements IProductionRepository {
  _FakeProductionRepository(this.producedQty);
  final int producedQty;

  @override
  Future<int> getCumulativeProductionQty({
    required String poNo,
    required String article,
    required String color,
    String? excludeId,
  }) async => producedQty;

  @override
  Future<int> getCumulativeProductionQuantity({
    required String poTagNo,
    required DateTime upToDate,
  }) async => producedQty;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ValidateProductionQuantityUseCase', () {
    test('accepts quantity within the available sewing quantity', () async {
      final useCase = ValidateProductionQuantityUseCase(
        _FakeSewingRepository(500, 500),
        _FakeProductionRepository(200),
      );
      final result = await useCase(
        poTagNo: 'TAG-1',
        productionDate: DateTime(2024, 7, 10),
        candidateQuantity: 300,
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
      );
      expect(result, isNull);
    });

    test('rejects zero or negative quantity', () async {
      final useCase = ValidateProductionQuantityUseCase(
        _FakeSewingRepository(500, 500),
        _FakeProductionRepository(0),
      );
      final result = await useCase(
        poTagNo: 'TAG-1',
        productionDate: DateTime(2024, 7, 10),
        candidateQuantity: 0,
      );
      expect(result, 'Quantity must be greater than zero');
    });

    test('rejects a quantity exceeding the remaining sewing balance', () async {
      final useCase = ValidateProductionQuantityUseCase(
        _FakeSewingRepository(500, 500),
        _FakeProductionRepository(350),
      );
      final result = await useCase(
        poTagNo: 'TAG-1',
        productionDate: DateTime(2024, 7, 10),
        candidateQuantity: 200,
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
      );
      expect(
        result,
        contains('Production quantity exceeds available sewing quantity'),
      );
      expect(result, contains('available: 150'));
    });

    test('only sewing completed on or before the date counts', () async {
      // Tag-wide lookup is date filtered by the repository; a value of 0 means
      // no sewing had completed by the selected date.
      final sewing = _FakeSewingRepository(0, 0);
      final useCase = ValidateProductionQuantityUseCase(sewing);
      final date = DateTime(2024, 7, 10);
      final result = await useCase(
        poTagNo: 'TAG-1',
        productionDate: date,
        candidateQuantity: 10,
      );
      expect(result, contains('available: 0'));
      expect(sewing.requestedUpToDate, date);
    });

    test('self-excludes the edited entry when updating', () async {
      // 500 sewn, 200 already produced by other entries → 300 available.
      final useCase = ValidateProductionQuantityUseCase(
        _FakeSewingRepository(500, 500),
        _FakeProductionRepository(200),
      );
      final result = await useCase.validateUpdate(
        productionId: 'prod-1',
        poTagNo: 'TAG-1',
        productionDate: DateTime(2024, 7, 10),
        candidateQuantity: 300,
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
      );
      expect(result, isNull);
    });

    test('availability is sewing minus production', () async {
      final useCase = ValidateProductionQuantityUseCase(
        _FakeSewingRepository(0, 900),
        _FakeProductionRepository(250),
      );
      final available = await useCase.availability(
        poTagNo: 'TAG-1',
        productionDate: DateTime(2024, 7, 10),
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
      );
      expect(available, 650);
    });
  });
}

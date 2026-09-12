import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/data/models/production/production_model.dart';
import 'package:footwear/domain/entities/production_entity.dart';
import 'package:footwear/domain/repositories/i_production_repository.dart';
import 'package:footwear/domain/usecases/issue/validate_issue_quantity_usecase.dart';

class MockProductionRepository implements IProductionRepository {
  int cumulativeQuantity = 100;

  @override
  Future<int> getCumulativeProductionQuantity({
    required String poTagNo,
    required DateTime upToDate,
  }) async => cumulativeQuantity;

  @override
  Future<Either<String, List<ProductionModel>>> getProductionList({
    int page = 0,
    int limit = 20,
  }) async => const Right([]);

  @override
  Future<Either<String, List<ProductionModel>>> byPoTag(String poTagNo) async =>
      const Right([]);

  @override
  Future<Either<String, void>> createProduction(ProductionEntity item) async =>
      const Right(null);

  @override
  Future<Either<String, void>> update(ProductionEntity item) async =>
      const Right(null);

  @override
  Future<Either<String, void>> delete(String id) async => const Right(null);
}

void main() {
  group('ValidateIssueQuantityUseCase', () {
    late MockProductionRepository repo;
    late ValidateIssueQuantityUseCase useCase;

    setUp(() {
      repo = MockProductionRepository();
      useCase = ValidateIssueQuantityUseCase(repo);
    });

    test('accepts quantity within cumulative production limit', () async {
      final result = await useCase(
        poTagNo: 'PO-001',
        issueDate: DateTime.now(),
        candidateQuantity: 50,
        alreadyIssued: 20,
      );
      expect(result, isNull);
    });

    test('rejects zero or negative quantity', () async {
      final result = await useCase(
        poTagNo: 'PO-001',
        issueDate: DateTime.now(),
        candidateQuantity: 0,
      );
      expect(result, 'Quantity must be greater than zero');
    });

    test('rejects quantity exceeding available production', () async {
      repo.cumulativeQuantity = 100;
      final result = await useCase(
        poTagNo: 'PO-001',
        issueDate: DateTime.now(),
        candidateQuantity: 60,
        alreadyIssued: 50,
      );
      expect(
        result,
        contains('Issue quantity exceeds available production quantity'),
      );
    });
  });
}

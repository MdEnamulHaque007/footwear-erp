import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/domain/repositories/i_cutting_repository.dart';
import 'package:footwear/domain/usecases/cutting/validate_cutting_quantity_usecase.dart';

/// Stub repository exposing the cumulative line read the validator depends on.
class FakeCuttingRepository implements ICuttingRepository {
  FakeCuttingRepository({this.cumulative = 0});

  /// Cumulative Cutting for the PO line (self-excluded by the repo).
  int cumulative;

  String? requestedExcludingId;

  @override
  Future<int> getCumulativeCuttingQuantityByLine({
    required String poNo,
    required String article,
    required String color,
    String? excludingId,
  }) async {
    requestedExcludingId = excludingId;
    return cumulative;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ValidateCuttingQuantityUseCase', () {
    late FakeCuttingRepository repo;
    late ValidateCuttingQuantityUseCase useCase;

    setUp(() {
      repo = FakeCuttingRepository();
      useCase = ValidateCuttingQuantityUseCase(repo);
    });

    test('accepts a quantity within the remaining PO balance', () async {
      repo.cumulative = 200;
      final result = await useCase(
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        poQuantity: 500,
        candidateQuantity: 300,
      );
      // available = 500 - 200 = 300
      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => -1), 300);
    });

    test('rejects zero or negative quantity', () async {
      final result = await useCase(
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        poQuantity: 500,
        candidateQuantity: 0,
      );
      expect(result.isLeft(), isTrue);
      expect(
        result.fold((e) => e, (_) => ''),
        'Quantity must be greater than zero',
      );
    });

    test('rejects a quantity exceeding the remaining PO balance', () async {
      repo.cumulative = 400;
      final result = await useCase(
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        poQuantity: 500,
        candidateQuantity: 150,
      );
      // available = 500 - 400 = 100
      expect(result.isLeft(), isTrue);
      expect(
        result.fold((e) => e, (_) => ''),
        contains('Cutting quantity exceeds available quantity'),
      );
      expect(result.fold((e) => e, (_) => ''), contains('available: 100'));
    });

    test('exactly consumes the remaining balance', () async {
      repo.cumulative = 400;
      final result = await useCase(
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        poQuantity: 500,
        candidateQuantity: 100,
      );
      expect(result.isRight(), isTrue);
    });

    test('self-excludes the edited entry when updating', () async {
      repo.cumulative = 100;
      await useCase(
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        poQuantity: 500,
        candidateQuantity: 50,
        excludingId: 'cut-1',
      );
      expect(repo.requestedExcludingId, 'cut-1');
    });

    test('rejects when the PO balance is already fully consumed', () async {
      repo.cumulative = 500;
      final result = await useCase(
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        poQuantity: 500,
        candidateQuantity: 1,
      );
      expect(result.isLeft(), isTrue);
      expect(result.fold((e) => e, (_) => ''), contains('available: 0'));
    });
  });
}

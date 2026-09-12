import 'package:dartz/dartz.dart';
import '../../repositories/i_cutting_repository.dart';

class ValidateCuttingQuantityUseCase {
  ValidateCuttingQuantityUseCase(this._repository);
  final ICuttingRepository _repository;

  Future<Either<String, int>> call({
    required String poNo,
    required String article,
    required String color,
    required int poQuantity,
    required int candidateQuantity,
    String? excludingId,
  }) async {
    if (candidateQuantity <= 0) {
      return const Left('Quantity must be greater than zero');
    }
    final cumulative = await _repository.getCumulativeCuttingQuantityByLine(
      poNo: poNo,
      article: article,
      color: color,
      excludingId: excludingId,
    );
    final available = poQuantity - cumulative;
    if (candidateQuantity > available) {
      return Left(
        'Cutting quantity exceeds available quantity (available: $available)',
      );
    }
    return Right(available);
  }
}

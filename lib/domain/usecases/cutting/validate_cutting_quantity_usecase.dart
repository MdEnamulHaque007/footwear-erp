import 'package:dartz/dartz.dart';
import '../../repositories/i_cutting_repository.dart';

/// Validates a Cutting quantity for a PO line.
///
/// Business rule: Cutting **may exceed** the PO line quantity. Excess is
/// intentional (e.g. extra cut after order completion) and must remain
/// recordable. Only non-positive quantities are rejected.
///
/// Returns [Right] with the remaining available amount
/// (`poQuantity - cumulative`). A **negative** value means the line is
/// already over-cut (or will be after this entry) and is still valid.
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
    // Soft-limit: over-PO cutting is allowed; [available] may be negative.
    return Right(available);
  }
}

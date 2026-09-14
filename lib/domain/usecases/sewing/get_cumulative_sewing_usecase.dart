import 'package:dartz/dartz.dart';
import '../../repositories/i_sewing_repository.dart';

/// Cumulative Sewing quantity for a PO line (`poNo` + `article` + `color`),
/// optionally self-excluding one document while editing.
class GetCumulativeSewingUseCase {
  GetCumulativeSewingUseCase(this._repository);
  final ISewingRepository _repository;

  Future<Either<String, int>> call({
    required String poNo,
    required String article,
    required String color,
    String? excludeId,
  }) async {
    try {
      final quantity = await _repository.getCumulativeSewingQty(
        poNo: poNo,
        article: article,
        color: color,
        excludeId: excludeId,
      );
      return Right(quantity);
    } catch (_) {
      return const Left('Unable to load cumulative sewing quantity');
    }
  }
}

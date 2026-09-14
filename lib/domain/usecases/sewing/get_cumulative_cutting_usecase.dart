import 'package:dartz/dartz.dart';
import '../../repositories/i_sewing_repository.dart';

/// Cumulative Cutting quantity for a PO line (`poNo` + `article` + `color`)
/// counting only Cutting records dated on or before [upToDate] — i.e. the
/// quantity a Sewing entry dated [upToDate] may consume.
class GetCumulativeCuttingUseCase {
  GetCumulativeCuttingUseCase(this._repository);
  final ISewingRepository _repository;

  Future<Either<String, int>> call({
    required String poNo,
    required String article,
    required String color,
    required DateTime upToDate,
    String? excludeId,
  }) async {
    try {
      final quantity = await _repository.getCumulativeCuttingQty(
        poNo: poNo,
        article: article,
        color: color,
        upToDate: upToDate,
        excludingId: excludeId,
      );
      return Right(quantity);
    } catch (_) {
      return const Left('Unable to load cumulative cutting quantity');
    }
  }
}

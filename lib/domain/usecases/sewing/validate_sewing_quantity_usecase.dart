import '../../repositories/i_cutting_repository.dart';

/// Ensures cumulative Sewing quantity never exceeds the cumulative
/// Cutting quantity available for the same PO tag up to the sewing date.
class ValidateSewingQuantityUseCase {
  ValidateSewingQuantityUseCase(this._cuttingRepository);
  final ICuttingRepository _cuttingRepository;

  /// Returns an error message when invalid, or null when valid.
  Future<String?> call({
    required String poTagNo,
    required DateTime sewingDate,
    required int candidateQuantity,
    int alreadySewn = 0,
  }) async {
    final cumulativeCutting = await _cuttingRepository
        .getCumulativeCuttingQuantity(poTagNo: poTagNo, upToDate: sewingDate);
    if (candidateQuantity <= 0) {
      return 'Quantity must be greater than zero';
    }
    if (alreadySewn + candidateQuantity > cumulativeCutting) {
      return 'Sewing quantity exceeds available cutting quantity '
          '(available: ${cumulativeCutting - alreadySewn})';
    }
    return null;
  }
}

import '../../repositories/i_sewing_repository.dart';

/// Ensures cumulative Production quantity never exceeds the cumulative
/// Sewing quantity available for the same PO tag up to the production date.
class ValidateProductionQuantityUseCase {
  ValidateProductionQuantityUseCase(this._sewingRepository);
  final ISewingRepository _sewingRepository;

  /// Returns an error message when invalid, or null when valid.
  Future<String?> call({
    required String poTagNo,
    required DateTime productionDate,
    required int candidateQuantity,
    int alreadyProduced = 0,
  }) async {
    final cumulativeSewing = await _sewingRepository
        .getCumulativeSewingQuantity(
          poTagNo: poTagNo,
          upToDate: productionDate,
        );
    if (candidateQuantity <= 0) {
      return 'Quantity must be greater than zero';
    }
    if (alreadyProduced + candidateQuantity > cumulativeSewing) {
      return 'Production quantity exceeds available sewing quantity '
          '(available: ${cumulativeSewing - alreadyProduced})';
    }
    return null;
  }
}

import '../../repositories/i_production_repository.dart';
import '../../repositories/i_sewing_repository.dart';

/// Ensures a Production entry never exceeds the Sewing quantity available for
/// the same PO line, counting **only Sewing completed on or before the selected
/// Production Date**:
///
///     available = cumulative Sewing (sewingDate <= productionDate)
///               − cumulative Production (same PO line)
///
/// On update the entry being edited is excluded from the Production total so a
/// record can be re-saved without counting itself twice.
class ValidateProductionQuantityUseCase {
  ValidateProductionQuantityUseCase(
    this._sewingRepository, [
    this._productionRepository,
  ]);
  final ISewingRepository _sewingRepository;
  final IProductionRepository? _productionRepository;

  /// Returns an error message when invalid, or null when valid.
  Future<String?> call({
    required String poTagNo,
    required DateTime productionDate,
    required int candidateQuantity,
    int alreadyProduced = 0,

    /// Optional PO line; when supplied the Sewing and Production totals are
    /// resolved per line, otherwise they fall back to the PO tag.
    String poNo = '',
    String article = '',
    String color = '',
    String? excludeId,

    /// When supplied the caller already loaded the availability (e.g. the form
    /// preview), so the repository round-trip is skipped.
    int? availableQuantity,
  }) async {
    if (candidateQuantity <= 0) {
      return 'Quantity must be greater than zero';
    }
    try {
      final available =
          availableQuantity ??
          await availability(
            poTagNo: poTagNo,
            poNo: poNo,
            article: article,
            color: color,
            productionDate: productionDate,
            excludeId: excludeId,
            alreadyProduced: alreadyProduced,
          );
      if (candidateQuantity > available) {
        return 'Production quantity exceeds available sewing quantity '
            '(available: $available)';
      }
      return null;
    } catch (_) {
      return 'Unable to validate production quantity. Please try again.';
    }
  }

  /// Update variant that self-excludes the edited entry.
  Future<String?> validateUpdate({
    required String productionId,
    required String poTagNo,
    required DateTime productionDate,
    required int candidateQuantity,
    String poNo = '',
    String article = '',
    String color = '',
  }) => call(
    poTagNo: poTagNo,
    productionDate: productionDate,
    candidateQuantity: candidateQuantity,
    poNo: poNo,
    article: article,
    color: color,
    excludeId: productionId,
  );

  /// Sewing (up to [productionDate]) − Production for one PO line/tag.
  Future<int> availability({
    required String poTagNo,
    required DateTime productionDate,
    String poNo = '',
    String article = '',
    String color = '',
    String? excludeId,
    int alreadyProduced = 0,
  }) async {
    final sewingTotal = poNo.isEmpty
        ? await _sewingRepository.getCumulativeSewingQuantity(
            tagNo: poTagNo,
            upToDate: productionDate,
          )
        : await _sewingRepository.getCumulativeSewingQty(
            poNo: poNo,
            article: article,
            color: color,
          );
    final repository = _productionRepository;
    final producedTotal = poNo.isNotEmpty && repository != null
        ? await repository.getCumulativeProductionQty(
            poNo: poNo,
            article: article,
            color: color,
            excludeId: excludeId,
          )
        : alreadyProduced;
    return sewingTotal - producedTotal;
  }
}

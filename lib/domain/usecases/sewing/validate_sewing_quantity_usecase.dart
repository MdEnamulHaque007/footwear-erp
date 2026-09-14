import '../../repositories/i_sewing_repository.dart';

/// Ensures a Sewing entry never exceeds the Cumulative Cutting quantity
/// available for the same PO line (`poNo` + `article` + `color`):
///
///     available = cumulative Cutting (cuttingDate <= sewingDate)
///               − cumulative Sewing (same PO line)
///
/// The Cutting side is date-filtered: only Cutting records dated on or before
/// [sewingDate] count, so a Sewing entry can never consume Cutting that has not
/// happened yet.
///
/// On update the entry being edited is excluded from the Sewing total so a
/// record can be re-saved without counting itself twice.
class ValidateSewingQuantityUseCase {
  ValidateSewingQuantityUseCase(this._sewingRepository);
  final ISewingRepository _sewingRepository;

  /// Returns an error message when invalid, or null when valid.
  Future<String?> call({
    required String poNo,
    required String article,
    required String color,
    required int candidateQuantity,
    DateTime? sewingDate,
    String? excludeId,

    /// When supplied the caller already loaded the availability (e.g. the form
    /// preview), so the repository round-trip is skipped.
    int? availableQuantity,
  }) async {
    if (candidateQuantity <= 0) {
      return 'Quantity must be greater than zero';
    }
    try {
      final available = availableQuantity ?? await availability(
        poNo: poNo,
        article: article,
        color: color,
        sewingDate: sewingDate,
        excludeId: excludeId,
      );
      if (candidateQuantity > available) {
        return 'Sewing quantity exceeds available cutting quantity '
            '(available: $available)';
      }
      return null;
    } catch (_) {
      return 'Unable to validate sewing quantity. Please try again.';
    }
  }

  /// Update variant that self-excludes the edited entry.
  Future<String?> validateUpdate({
    required String sewingId,
    required String poNo,
    required String article,
    required String color,
    required int candidateQuantity,
    DateTime? sewingDate,
  }) => call(
    poNo: poNo,
    article: article,
    color: color,
    candidateQuantity: candidateQuantity,
    sewingDate: sewingDate,
    excludeId: sewingId,
  );

  /// Cutting (date-filtered) − Sewing for one PO line.
  Future<int> availability({
    required String poNo,
    required String article,
    required String color,
    DateTime? sewingDate,
    String? excludeId,
  }) async {
    final hasLine = poNo.isNotEmpty && article.isNotEmpty && color.isNotEmpty;
    if (!hasLine) return 0;
    final upToDate = sewingDate ?? DateTime.now();
    // The line-wide Cutting total (no date filter) is used as the fallback so
    // legacy records without a `cuttingDate` still validate.
    final cuttingTotal = await _sewingRepository.getCumulativeCuttingQty(
      poNo: poNo,
      article: article,
      color: color,
      upToDate: upToDate,
    );
    final sewingTotal = await _sewingRepository.getCumulativeSewingQty(
      poNo: poNo,
      article: article,
      color: color,
      excludeId: excludeId,
    );
    return cuttingTotal - sewingTotal;
  }
}

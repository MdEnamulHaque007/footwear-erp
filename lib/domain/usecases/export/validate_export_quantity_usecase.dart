import '../../repositories/i_export_repository.dart';

/// Ensures an Export never exceeds the Issue quantity available for the same PO
/// line, counting **only Issue completed on or before the selected Export
/// Date**:
///
///     available = cumulative Issue (issueDate <= exportDate)
///               − cumulative Export (same PO line)
///
/// On update the entry being edited is excluded from the Export total.
class ValidateExportQuantityUseCase {
  ValidateExportQuantityUseCase(this._exportRepository);
  final IExportRepository _exportRepository;

  /// Returns an error message when invalid, or null when valid.
  Future<String?> call({
    required String poNo,
    required String article,
    required String color,
    required int candidateQuantity,
    required DateTime exportDate,
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
            poNo: poNo,
            article: article,
            color: color,
            exportDate: exportDate,
            excludeId: excludeId,
          );
      if (candidateQuantity > available) {
        return 'Export quantity exceeds available issue quantity '
            '(available: $available)';
      }
      return null;
    } catch (_) {
      return 'Unable to validate export quantity. Please try again.';
    }
  }

  /// Update variant that self-excludes the edited entry.
  Future<String?> validateUpdate({
    required String exportId,
    required String poNo,
    required String article,
    required String color,
    required int candidateQuantity,
    required DateTime exportDate,
  }) => call(
    poNo: poNo,
    article: article,
    color: color,
    candidateQuantity: candidateQuantity,
    exportDate: exportDate,
    excludeId: exportId,
  );

  /// Issue (up to [exportDate]) − Export for one PO line.
  Future<int> availability({
    required String poNo,
    required String article,
    required String color,
    required DateTime exportDate,
    String? excludeId,
  }) async {
    if (poNo.isEmpty || article.isEmpty || color.isEmpty) return 0;
    final issue = await _exportRepository.getCumulativeIssueQty(
      poNo: poNo,
      article: article,
      color: color,
      upToDate: exportDate,
      excludeId: excludeId,
    );
    final exported = await _exportRepository.getCumulativeExportQty(
      poNo: poNo,
      article: article,
      color: color,
      excludeId: excludeId,
    );
    return issue - exported;
  }
}

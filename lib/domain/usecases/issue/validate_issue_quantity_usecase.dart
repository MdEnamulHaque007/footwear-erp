/// ============================================================================
/// ফাইল: lib/domain/usecases/issue/validate_issue_quantity_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Finished Goods Issue
/// উদ্দেশ্য: Finished Goods Issue মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: ValidateIssueQuantityUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../repositories/i_issue_repository.dart';

/// Ensures an Issue never exceeds the Production quantity available for the
/// same PO line, counting **only Production completed on or before the selected
/// Issue Date**:
///
///     available = cumulative Production (productionDate <= issueDate)
///               − cumulative Issue (same PO line)
///
/// The legacy tag-based signature (`poTagNo` + `alreadyIssued`) is preserved so
/// existing callers keep working.
class ValidateIssueQuantityUseCase {
  ValidateIssueQuantityUseCase(this._issueRepository);
  final IIssueRepository _issueRepository;

  /// Returns an error message when invalid, or null when valid.
  Future<String?> call({
    required String poTagNo,
    required DateTime issueDate,
    required int candidateQuantity,
    int alreadyIssued = 0,

    /// Optional PO line; when supplied the Production and Issue totals are
    /// resolved per line, otherwise the caller-provided [alreadyIssued] is used.
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
      if (availableQuantity != null) {
        if (candidateQuantity > availableQuantity) {
          return 'Issue quantity exceeds available production quantity '
              '(available: $availableQuantity)';
        }
        return null;
      }
      final available = await availability(
        poTagNo: poTagNo,
        issueDate: issueDate,
        poNo: poNo,
        article: article,
        color: color,
        excludeId: excludeId,
        alreadyIssued: alreadyIssued,
      );
      if (candidateQuantity > available) {
        return 'Issue quantity exceeds available production quantity '
            '(available: $available)';
      }
      return null;
    } catch (_) {
      return 'Unable to validate issue quantity. Please try again.';
    }
  }

  /// Update variant that self-excludes the edited entry.
  Future<String?> validateUpdate({
    required String issueId,
    required String poTagNo,
    required DateTime issueDate,
    required int candidateQuantity,
    String poNo = '',
    String article = '',
    String color = '',
  }) => call(
    poTagNo: poTagNo,
    issueDate: issueDate,
    candidateQuantity: candidateQuantity,
    poNo: poNo,
    article: article,
    color: color,
    excludeId: issueId,
  );

  /// Production (up to [issueDate]) − Issue for one PO line/tag.
  Future<int> availability({
    required String poTagNo,
    required DateTime issueDate,
    String poNo = '',
    String article = '',
    String color = '',
    String? excludeId,
    int alreadyIssued = 0,
  }) async {
    if (poNo.isNotEmpty && article.isNotEmpty && color.isNotEmpty) {
      final production = await _issueRepository.getCumulativeProductionQty(
        poNo: poNo,
        article: article,
        color: color,
        upToDate: issueDate,
      );
      final issued = await _issueRepository.getCumulativeIssueQty(
        poNo: poNo,
        article: article,
        color: color,
        excludeId: excludeId,
      );
      return production - issued;
    }
    // Legacy tag-based path. The caller either supplies `alreadyIssued`
    // (previously computed from Production) or the cumulative Issue recorded
    // against the tag is resolved from the repository.
    final issued = await _issueRepository.getCumulativeIssueQuantity(
      poTagNo: poTagNo,
      upToDate: issueDate,
      excludingId: excludeId,
    );
    final baseline = alreadyIssued > 0 ? alreadyIssued : issued;
    return baseline - issued;
  }
}

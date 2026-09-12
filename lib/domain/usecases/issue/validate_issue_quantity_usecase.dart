import '../../repositories/i_production_repository.dart';
import '../../repositories/i_issue_repository.dart';

/// Ensures cumulative Issue quantity never exceeds the cumulative
/// Production quantity available for the same PO tag up to the issue date.
class ValidateIssueQuantityUseCase {
  ValidateIssueQuantityUseCase(
    this._productionRepository, [
    this._issueRepository,
  ]);
  final IProductionRepository _productionRepository;
  final IIssueRepository? _issueRepository;

  /// Returns an error message when invalid, or null when valid.
  Future<String?> call({
    required String poTagNo,
    required DateTime issueDate,
    required int candidateQuantity,
    int alreadyIssued = 0,
  }) async {
    if (candidateQuantity <= 0) return 'Quantity must be greater than zero';
    try {
      final cumulativeProduction = await _productionRepository
          .getCumulativeProductionQuantity(
            poTagNo: poTagNo,
            upToDate: issueDate,
          );
      if (alreadyIssued + candidateQuantity > cumulativeProduction) {
        return 'Issue quantity exceeds available production quantity '
            '(available: ${cumulativeProduction - alreadyIssued})';
      }
    } on Exception {
      return 'Unable to validate issue quantity. Please try again.';
    }
    return null;
  }

  Future<String?> validateUpdate({
    required String issueId,
    required String poTagNo,
    required DateTime issueDate,
    required int candidateQuantity,
  }) async {
    if (_issueRepository == null) {
      return 'Unable to validate issue quantity. Please try again.';
    }
    try {
      final alreadyIssued = await _issueRepository.getCumulativeIssueQuantity(
        poTagNo: poTagNo,
        upToDate: issueDate,
        excludingId: issueId,
      );
      return call(
        poTagNo: poTagNo,
        issueDate: issueDate,
        candidateQuantity: candidateQuantity,
        alreadyIssued: alreadyIssued,
      );
    } on Exception {
      return 'Unable to validate issue quantity. Please try again.';
    }
  }
}

import 'package:dartz/dartz.dart';
import '../../repositories/i_issue_repository.dart';

/// Cumulative quantities behind an Issue entry for one PO line: Production
/// completed on or before [issueDate], the Issue already recorded, and the
/// resulting available balance.
///
/// `available = productionQuantity − issueQuantity`
class GetIssueAvailabilityUseCase {
  GetIssueAvailabilityUseCase(this._repository);
  final IIssueRepository _repository;

  Future<Either<String, IssueAvailability>> call({
    required String poNo,
    required String article,
    required String color,
    required DateTime issueDate,
    String? excludeId,
  }) async {
    try {
      final production = await _repository.getCumulativeProductionQty(
        poNo: poNo,
        article: article,
        color: color,
        upToDate: issueDate,
      );
      final issued = await _repository.getCumulativeIssueQty(
        poNo: poNo,
        article: article,
        color: color,
        excludeId: excludeId,
      );
      return Right(
        IssueAvailability(
          productionQuantity: production,
          issueQuantity: issued,
          availableQuantity: (production - issued).clamp(0, production).toInt(),
        ),
      );
    } catch (_) {
      return const Left('Unable to load issue availability');
    }
  }
}

/// Result of [GetIssueAvailabilityUseCase].
class IssueAvailability {
  const IssueAvailability({
    required this.productionQuantity,
    required this.issueQuantity,
    required this.availableQuantity,
  });
  final int productionQuantity;
  final int issueQuantity;
  final int availableQuantity;
}

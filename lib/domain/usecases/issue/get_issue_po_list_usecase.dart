import 'package:dartz/dartz.dart';
import '../../repositories/i_issue_repository.dart';

/// PO No list for the Issue form's PO dropdown.
///
/// Sourced from the Production entries, so only POs that have actually been
/// produced can be issued.
class GetIssuePOListUseCase {
  GetIssuePOListUseCase(this._repository);
  final IIssueRepository _repository;

  Future<Either<String, List<String>>> call() =>
      _repository.getProductionEntryPONoList();
}

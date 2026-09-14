import 'package:dartz/dartz.dart';
import '../../entities/issue_entity.dart';
import '../../repositories/i_issue_repository.dart';

/// Distinct Article + Color pairs recorded in the Production entries of a PO.
///
/// Drives the Issue form's cascading dropdowns: a line can only be issued once
/// it has been produced.
class GetIssueArticleColorsUseCase {
  GetIssueArticleColorsUseCase(this._repository);
  final IIssueRepository _repository;

  Future<Either<String, List<ProductionLine>>> call(String poNo) =>
      _repository.getProductionEntryLines(poNo);
}

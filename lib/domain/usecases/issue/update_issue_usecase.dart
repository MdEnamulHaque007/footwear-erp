import 'package:dartz/dartz.dart';
import '../../entities/issue_entity.dart';
import '../../repositories/i_issue_repository.dart';
import 'validate_issue_quantity_usecase.dart';

class UpdateIssueUseCase {
  UpdateIssueUseCase(this._repository, this._validate);
  final IIssueRepository _repository;
  final ValidateIssueQuantityUseCase _validate;

  Future<Either<String, void>> call(IssueEntity item) async {
    final error = await _validate.validateUpdate(
      issueId: item.id ?? '',
      poTagNo: item.poTagNo,
      issueDate: item.issueDate,
      candidateQuantity: item.quantity,
    );
    if (error != null) return Left(error);
    return _repository.update(item);
  }
}

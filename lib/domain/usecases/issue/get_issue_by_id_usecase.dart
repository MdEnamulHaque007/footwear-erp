import 'package:dartz/dartz.dart';
import '../../repositories/i_issue_repository.dart';
import '../../../data/models/issue/issue_model.dart';

/// Loads a single Issue record by document id (detail / edit screens).
class GetIssueByIdUseCase {
  GetIssueByIdUseCase(this._repository);
  final IIssueRepository _repository;

  Future<Either<String, IssueModel?>> call(String id) => _repository.byId(id);
}

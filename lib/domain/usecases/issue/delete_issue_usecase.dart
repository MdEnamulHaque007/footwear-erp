import 'package:dartz/dartz.dart';
import '../../repositories/i_issue_repository.dart';

class DeleteIssueUseCase {
  DeleteIssueUseCase(this._repository);
  final IIssueRepository _repository;
  Future<Either<String, void>> call(String id) => _repository.delete(id);
}

import 'package:dartz/dartz.dart';
import '../../../data/models/issue/issue_model.dart';
import '../../repositories/i_issue_repository.dart';

class GetIssueListUseCase {
  GetIssueListUseCase(this._repository);
  final IIssueRepository _repository;
  Future<Either<String, List<IssueModel>>> call({
    int page = 0,
    int limit = 20,
  }) => _repository.getIssueList(page: page, limit: limit);
}

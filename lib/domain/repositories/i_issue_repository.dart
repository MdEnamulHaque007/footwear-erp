import 'package:dartz/dartz.dart';
import '../entities/issue_entity.dart';
import '../../data/models/issue/issue_model.dart';

abstract interface class IIssueRepository {
  Future<Either<String, List<IssueModel>>> getIssueList({
    int page = 0,
    int limit = 20,
  });
  Future<Either<String, List<IssueModel>>> byPoTag(String poTagNo);
  Future<Either<String, void>> createIssue(IssueEntity item);
  Future<Either<String, void>> update(IssueEntity item);
  Future<Either<String, void>> delete(String id);
  Future<int> getCumulativeIssueQuantity({
    required String poTagNo,
    required DateTime upToDate,
    String? excludingId,
  });
}

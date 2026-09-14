import 'package:dartz/dartz.dart';
import '../../repositories/i_master_lc_repository.dart';

/// Distinct Project list for the Master LC form's predefined dropdown.
class GetProjectListUseCase {
  GetProjectListUseCase(this._repository);
  final IMasterLCRepository _repository;

  Future<Either<String, List<String>>> call() =>
      _repository.getProjectList();
}

import 'package:dartz/dartz.dart';
import '../../repositories/i_master_lc_repository.dart';

/// Distinct Company list for the Master LC form's predefined dropdown.
class GetCompanyListUseCase {
  GetCompanyListUseCase(this._repository);
  final IMasterLCRepository _repository;

  Future<Either<String, List<String>>> call() =>
      _repository.getCompanyList();
}

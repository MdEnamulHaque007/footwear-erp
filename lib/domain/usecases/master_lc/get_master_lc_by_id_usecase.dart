import 'package:dartz/dartz.dart';
import '../../entities/master_lc_entity.dart';
import '../../repositories/i_master_lc_repository.dart';

class GetMasterLCByIdUseCase {
  GetMasterLCByIdUseCase(this._repository);
  final IMasterLCRepository _repository;

  Future<Either<String, MasterLCEntity?>> call(String id) =>
      _repository.byId(id);
}

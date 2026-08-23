import 'package:dartz/dartz.dart';
import '../../entities/master_lc_entity.dart';
import '../../repositories/i_master_lc_repository.dart';

class CreateMasterLCUseCase {
  CreateMasterLCUseCase(this._repository);
  final IMasterLCRepository _repository;

  Future<Either<String, void>> call(MasterLCEntity item) =>
      _repository.createMasterLC(item);
}

import 'package:dartz/dartz.dart';
import '../../entities/cutting_entity.dart';
import '../../repositories/i_cutting_repository.dart';

class UpdateCuttingUseCase {
  UpdateCuttingUseCase(this._repository);
  final ICuttingRepository _repository;
  Future<Either<String, void>> call(CuttingEntity item) =>
      _repository.update(item);
}

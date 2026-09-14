import 'package:dartz/dartz.dart';
import '../../entities/cutting_entity.dart';
import '../../repositories/i_cutting_repository.dart';

/// Updates a Cutting entry. The repository retains the persisted Sl. and
/// self-excludes the edited document from the cumulative Cutting total.
class UpdateCuttingUseCase {
  UpdateCuttingUseCase(this._repository);
  final ICuttingRepository _repository;
  Future<Either<String, void>> call(CuttingEntity item) =>
      _repository.updateWithTransaction(item);
}

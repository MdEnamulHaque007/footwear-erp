import 'package:dartz/dartz.dart';
import '../../entities/production_entity.dart';
import '../../repositories/i_production_repository.dart';

class UpdateProductionUseCase {
  UpdateProductionUseCase(this._repository);
  final IProductionRepository _repository;
  Future<Either<String, void>> call(ProductionEntity item) =>
      _repository.update(item);
}

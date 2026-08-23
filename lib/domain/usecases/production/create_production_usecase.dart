import 'package:dartz/dartz.dart';
import '../../entities/production_entity.dart';
import '../../repositories/i_production_repository.dart';
import 'validate_production_quantity_usecase.dart';

class CreateProductionUseCase {
  CreateProductionUseCase(this._repository, this._validate);
  final IProductionRepository _repository;
  final ValidateProductionQuantityUseCase _validate;

  Future<Either<String, void>> call(ProductionEntity item) async {
    final error = await _validate(
      poTagNo: item.poTagNo,
      productionDate: item.productionDate,
      candidateQuantity: item.quantity,
    );
    if (error != null) return Left(error);
    return _repository.createProduction(item);
  }
}

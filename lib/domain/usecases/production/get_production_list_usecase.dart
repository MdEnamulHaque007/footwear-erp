import 'package:dartz/dartz.dart';
import '../../../data/models/production/production_model.dart';
import '../../repositories/i_production_repository.dart';

class GetProductionListUseCase {
  GetProductionListUseCase(this._repository);
  final IProductionRepository _repository;
  Future<Either<String, List<ProductionModel>>> call({
    int page = 0,
    int limit = 20,
  }) => _repository.getProductionList(page: page, limit: limit);
}

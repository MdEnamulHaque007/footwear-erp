import 'package:dartz/dartz.dart';
import '../entities/production_entity.dart';
import '../../data/models/production/production_model.dart';

abstract interface class IProductionRepository {
  Future<Either<String, List<ProductionModel>>> getProductionList({
    int page = 0,
    int limit = 20,
  });
  Future<Either<String, List<ProductionModel>>> byPoTag(String poTagNo);
  Future<Either<String, void>> createProduction(ProductionEntity item);
  Future<Either<String, void>> update(ProductionEntity item);
  Future<Either<String, void>> delete(String id);
}

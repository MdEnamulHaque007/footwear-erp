import 'package:dartz/dartz.dart';
import '../entities/cutting_entity.dart';
import '../../data/models/cutting/cutting_model.dart';

abstract interface class ICuttingRepository {
  Future<Either<String, List<CuttingModel>>> getCuttingList({
    int page = 0,
    int limit = 20,
  });
  Future<Either<String, List<CuttingModel>>> byPoTag(String poTagNo);
  Future<Either<String, void>> createCutting(CuttingEntity item);
  Future<Either<String, void>> update(CuttingEntity item);
  Future<Either<String, void>> delete(String id);
  Future<int> getCumulativeCuttingQuantity({
    required String poTagNo,
    required DateTime upToDate,
  });
}

import 'package:dartz/dartz.dart';
import '../entities/sewing_entity.dart';
import '../../data/models/sewing/sewing_model.dart';

abstract interface class ISewingRepository {
  Future<Either<String, List<SewingModel>>> getSewingList({
    int page = 0,
    int limit = 20,
  });
  Future<Either<String, List<SewingModel>>> byPoTag(String poTagNo);
  Future<Either<String, void>> createSewing(SewingEntity item);
  Future<Either<String, void>> update(SewingEntity item);
  Future<Either<String, void>> delete(String id);
}

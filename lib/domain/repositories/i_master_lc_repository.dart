import 'package:dartz/dartz.dart';
import '../entities/master_lc_entity.dart';
import '../../data/models/master_lc/master_lc_model.dart';

abstract interface class IMasterLCRepository {
  Future<Either<String, List<MasterLCModel>>> getMasterLCList({int page = 0, int limit = 20});
  Future<Either<String, MasterLCEntity?>> byTag(String tag);
  Future<Either<String, MasterLCEntity?>> byId(String id);
  Future<Either<String, void>> createMasterLC(MasterLCEntity item);
  Future<Either<String, void>> update(MasterLCEntity item);
  Future<Either<String, void>> delete(String id);
}

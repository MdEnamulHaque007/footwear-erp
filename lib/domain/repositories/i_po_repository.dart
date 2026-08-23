import 'package:dartz/dartz.dart';
import '../entities/po_entity.dart';
import '../../data/models/purchase_order/po_model.dart';

abstract interface class IPORepository {
  Future<Either<String, List<POModel>>> getPOList({int page = 0, int limit = 20});
  Future<Either<String, List<POModel>>> byTag(String tag);
  Future<Either<String, void>> createPO(POEntity item);
  Future<Either<String, void>> update(POEntity item);
  Future<Either<String, void>> delete(String id);
}

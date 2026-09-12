import 'package:dartz/dartz.dart';
import '../entities/cutting_entity.dart';
import '../../data/models/cutting/cutting_model.dart';
import '../../data/models/purchase_order/po_model.dart';

abstract interface class ICuttingRepository {
  Future<Either<String, List<CuttingModel>>> getCuttingList({
    int page = 0,
    int limit = 20,
  });
  Future<Either<String, List<CuttingModel>>> byPoTag(String poTagNo);
  Future<Either<String, CuttingModel?>> byId(String id);
  Future<Either<String, List<CuttingModel>>> byLine({
    required String poNo,
    required String article,
    required String color,
  });
  Future<Either<String, List<String>>> getPONoList();
  Future<Either<String, List<POModel>>> getPOListForDropdown();
  Future<Either<String, POModel?>> getPOByNo(String poNo);
  Future<Either<String, void>> createCutting(CuttingEntity item);
  Future<Either<String, void>> update(CuttingEntity item);
  Future<Either<String, void>> delete(String id);
  Future<int> getCumulativeCuttingQuantity({
    required String poTagNo,
    required DateTime upToDate,
  });
  Future<int> getCumulativeCuttingQuantityByLine({
    required String poNo,
    required String article,
    required String color,
    String? excludingId,
  });
}

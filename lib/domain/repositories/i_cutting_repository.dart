import 'package:dartz/dartz.dart';
import '../entities/cutting_entity.dart';
import '../../data/models/cutting/cutting_model.dart';
import '../../data/models/purchase_order/po_model.dart';

abstract interface class ICuttingRepository {
  Future<Either<String, List<CuttingModel>>> getCuttingList({
    int page = 0,
    int limit = 20,
  });
  Future<Either<String, String>> getNextVoucherNo(DateTime date);
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

  /// Distinct Article + Color pairs recorded in the PO line items of [poNo].
  ///
  /// Keeps the Cutting form's cascading dropdowns aligned with the typed line
  /// value used by Production / Issue / Export.
  Future<Either<String, List<CuttingLine>>> getPOLines(String poNo);

  /// Creates a Cutting entry transactionally after re-validating the PO line
  /// quantity against persisted documents.
  Future<Either<String, void>> createWithTransaction(CuttingEntity item);

  /// Updates a Cutting entry transactionally, self-excluding the edited
  /// document from the cumulative Cutting total.
  Future<Either<String, void>> updateWithTransaction(CuttingEntity item);

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

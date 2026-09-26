import 'package:dartz/dartz.dart';
import '../entities/sewing_entity.dart';
import '../../data/models/sewing/sewing_model.dart';
import '../../data/models/purchase_order/po_model.dart';

abstract interface class ISewingRepository {
  Future<Either<String, List<SewingModel>>> getSewingList({
    int page = 0,
    int limit = 20,
  });
  Future<Either<String, List<SewingModel>>> byTagNo(String tagNo);
  Future<Either<String, SewingModel?>> byId(String id);
  Future<Either<String, List<SewingModel>>> byLine({
    required String poNo,
    required String article,
    required String color,
  });
  Future<Either<String, List<String>>> getPONoList();

  /// Distinct PO No list taken from the Cutting entries.
  ///
  /// Sewing is only valid for a PO that has actually been cut, so the Sewing
  /// form's PO dropdown is sourced from `cuttings` rather than from the full
  /// Purchase Order collection.
  Future<Either<String, List<String>>> getCuttingEntryPONoList();
  Future<Either<String, List<POModel>>> getPOListForDropdown();
  Future<Either<String, POModel?>> getPOByNo(String poNo);

  /// Creates a Sewing entry inside a Firestore transaction so the cumulative
  /// Cutting check and the write happen atomically.
  Future<Either<String, void>> createWithTransaction(SewingEntity item);

  /// Updates a Sewing entry inside a Firestore transaction, self-excluding the
  /// edited document from the cumulative Sewing total.
  Future<Either<String, void>> updateWithTransaction(SewingEntity item);

  Future<Either<String, void>> createSewing(SewingEntity item);
  Future<Either<String, void>> update(SewingEntity item);
  Future<Either<String, void>> delete(String id);

  /// Cumulative Cutting quantity for a PO line (`poNo` + `article` + `color`)
  /// counting only Cutting records dated on or before [upToDate].
  Future<int> getCumulativeCuttingQty({
    required String poNo,
    required String article,
    required String color,
    required DateTime upToDate,
    String? excludingId,
  });

  /// Cumulative Sewing quantity for a PO line (`poNo` + `article` + `color`),
  /// optionally excluding one document (used when editing).
  Future<int> getCumulativeSewingQty({
    required String poNo,
    required String article,
    required String color,
    String? excludeId,
  });

  /// Cumulative Sewing quantity for a PO tag up to [upToDate].
  /// Kept for the downstream production validation chain.
  Future<int> getCumulativeSewingQuantity({
    required String tagNo,
    required DateTime upToDate,
  });
}


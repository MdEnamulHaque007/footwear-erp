import 'package:dartz/dartz.dart';
import '../entities/export_entity.dart';
import '../../data/models/export/export_model.dart';
import '../../data/models/purchase_order/po_model.dart';

abstract interface class IExportRepository {
  Future<Either<String, List<ExportModel>>> getExportList({
    int page = 0,
    int limit = 20,
  });
  Future<Either<String, List<ExportModel>>> byPoTag(String poTagNo);
  Future<Either<String, ExportModel?>> byId(String id);
  Future<Either<String, List<ExportModel>>> byLine({
    required String poNo,
    required String article,
    required String color,
  });

  /// Distinct PO No list taken from the Issue entries, so the Export form only
  /// offers POs that have actually been issued.
  Future<Either<String, List<String>>> getIssueEntryPONoList();

  /// Distinct Article + Color pairs recorded in the Issue entries of [poNo].
  Future<Either<String, List<IssueLine>>> getIssueEntryLines(String poNo);

  /// PO header (Tag / Company / Project + line items) for a PO No.
  Future<Either<String, POModel?>> poByNo(String poNo);

  /// Cumulative Issue for a PO line (`poNo` + `article` + `color`) counting only
  /// Issue dated on or before [upToDate].
  Future<int> getCumulativeIssueQty({
    required String poNo,
    required String article,
    required String color,
    required DateTime upToDate,
    String? excludeId,
  });

  /// Cumulative Export for a PO line (`poNo` + `article` + `color`),
  /// optionally excluding one document (used when editing).
  Future<int> getCumulativeExportQty({
    required String poNo,
    required String article,
    required String color,
    String? excludeId,
  });

  /// Creates an Export inside a Firestore transaction (concurrent-safe).
  Future<Either<String, void>> createWithTransaction(ExportEntity item);

  /// Updates an Export inside a Firestore transaction, self-excluding the
  /// edited document from the cumulative Export total.
  Future<Either<String, void>> updateWithTransaction(ExportEntity item);

  Future<Either<String, void>> createExport(ExportEntity item);
  Future<Either<String, void>> update(ExportEntity item);
  Future<Either<String, void>> delete(String id);
}

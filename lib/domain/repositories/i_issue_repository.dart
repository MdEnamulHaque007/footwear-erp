/// ============================================================================
/// ফাইল: lib/domain/repositories/i_issue_repository.dart
/// স্তর: Domain Repository Contract | মডিউল: Finished Goods Issue
/// উদ্দেশ্য: Finished Goods Issue data access-এর interface নির্ধারণ করে; implementation data layer-এ থাকে।
/// প্রধান অংশ: top-level configuration ও helper declarations
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../entities/issue_entity.dart';
import '../../data/models/issue/issue_model.dart';
import '../../data/models/purchase_order/po_model.dart';

abstract interface class IIssueRepository {
  Future<Either<String, List<IssueModel>>> getIssueList({
    int page = 0,
    int limit = 20,
  });
  Future<Either<String, List<IssueModel>>> byPoTag(String poTagNo);
  Future<Either<String, IssueModel?>> byId(String id);
  Future<Either<String, List<IssueModel>>> byLine({
    required String poNo,
    required String article,
    required String color,
  });

  /// Distinct PO No list taken from the Production entries, so the Issue form
  /// only offers POs that have actually been produced.
  Future<Either<String, List<String>>> getProductionEntryPONoList();

  /// Distinct Article + Color pairs recorded in the Production entries of
  /// [poNo].
  Future<Either<String, List<ProductionLine>>> getProductionEntryLines(
    String poNo,
  );

  /// PO header (Tag / Company / Project + line items) for a PO No.
  Future<Either<String, POModel?>> poByNo(String poNo);

  /// Cumulative Production for a PO line (`poNo` + `article` + `color`)
  /// counting only Production dated on or before [upToDate].
  Future<int> getCumulativeProductionQty({
    required String poNo,
    required String article,
    required String color,
    required DateTime upToDate,
    String? excludeId,
  });

  /// Cumulative Issue for a PO line (`poNo` + `article` + `color`),
  /// optionally excluding one document (used when editing).
  Future<int> getCumulativeIssueQty({
    required String poNo,
    required String article,
    required String color,
    String? excludeId,
  });

  /// Cumulative Issue for a PO tag up to [upToDate]. Kept for legacy callers.
  Future<int> getCumulativeIssueQuantity({
    required String poTagNo,
    required DateTime upToDate,
    String? excludingId,
  });

  /// Creates an Issue inside a Firestore transaction (concurrent-safe).
  Future<Either<String, void>> createWithTransaction(IssueEntity item);

  /// Updates an Issue inside a Firestore transaction, self-excluding the
  /// edited document from the cumulative Issue total.
  Future<Either<String, void>> updateWithTransaction(IssueEntity item);

  Future<Either<String, void>> createIssue(IssueEntity item);
  Future<Either<String, void>> update(IssueEntity item);
  Future<Either<String, void>> delete(String id);
}

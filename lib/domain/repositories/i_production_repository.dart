/// ============================================================================
/// ফাইল: lib/domain/repositories/i_production_repository.dart
/// স্তর: Domain Repository Contract | মডিউল: Production/Lasting
/// উদ্দেশ্য: Production/Lasting data access-এর interface নির্ধারণ করে; implementation data layer-এ থাকে।
/// প্রধান অংশ: top-level configuration ও helper declarations
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
﻿import 'package:dartz/dartz.dart';
import '../entities/production_entity.dart';
import '../../data/models/production/production_model.dart';
import '../../data/models/purchase_order/po_model.dart';

abstract interface class IProductionRepository {
  Future<Either<String, List<ProductionModel>>> getProductionList({
    int page = 0,
    int limit = 20,
  });
  Future<Either<String, List<ProductionModel>>> byPoTag(String poTagNo);
  Future<Either<String, ProductionModel?>> byId(String id);
  Future<Either<String, List<ProductionModel>>> byLine({
    required String poNo,
    required String article,
    required String color,
  });

  /// Distinct PO No list taken from the Sewing entries, so the Production form
  /// only offers POs that have actually been sewn.
  Future<Either<String, List<String>>> getSewingEntryPONoList();

  /// Distinct PO No list taken from the Cutting entries.
  ///
  /// Production is only valid for a PO that has actually been cut, so the
  /// Production form's PO dropdown can be sourced from `cuttings`.
  Future<Either<String, List<String>>> getCuttingEntryPONoList();

  /// Distinct Article + Color pairs recorded in the Sewing entries of [poNo].
  Future<Either<String, List<SewingLine>>> getSewingEntryLines(String poNo);

  /// PO header (Tag / Company / Project + line items) for a PO No.
  Future<Either<String, POModel?>> poByNo(String poNo);

  Future<Either<String, void>> createWithTransaction(ProductionEntity item);
  Future<Either<String, void>> updateWithTransaction(ProductionEntity item);
  Future<Either<String, void>> createProduction(ProductionEntity item);
  Future<Either<String, void>> update(ProductionEntity item);
  Future<Either<String, void>> delete(String id);
  Future<int> getCumulativeProductionQuantity({
    required String poTagNo,
    required DateTime upToDate,
  });

  /// Cumulative Production for a PO line (poNo + article + color),
  /// optionally excluding one document (used when editing).
  Future<int> getCumulativeProductionQty({
    required String poNo,
    required String article,
    required String color,
    String? excludeId,
  });
}

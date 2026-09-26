/// ============================================================================
/// ফাইল: lib/domain/repositories/i_po_repository.dart
/// স্তর: Domain Repository Contract | মডিউল: ERP Common
/// উদ্দেশ্য: ERP Common data access-এর interface নির্ধারণ করে; implementation data layer-এ থাকে।
/// প্রধান অংশ: top-level configuration ও helper declarations
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../entities/po_entity.dart';
import '../../data/models/purchase_order/po_model.dart';

abstract interface class IPORepository {
  Future<Either<String, List<POModel>>> getPOList({int page = 0, int limit = 20});
  Future<Either<String, List<POModel>>> byTag(String tag);
  Future<Either<String, POModel?>> byId(String id);

  /// Next available serial number (max stored `sl` + 1, or 1 when empty).
  ///
  /// SRS Rule 1: the Sl. is auto-generated. This is the spec'd reader; the
  /// authoritative allocation happens inside [createWithTransaction], which
  /// increments a transactionally-guarded counter document so concurrent
  /// creates can never receive the same Sl.
  Future<int> getMaxSl();

  /// Whether [poNo] is free. PO No is unique **globally**.
  ///
  /// [excludeId] self-excludes the record being edited.
  Future<bool> isPoNoUnique(String poNo, {String? excludeId});

  /// Creates the PO inside a Firestore transaction, re-validating the Master LC
  /// quantity/value limits against the persisted documents and allocating the
  /// next Sl. atomically.
  Future<Either<String, void>> createWithTransaction(POEntity item);

  /// Updates the PO inside a Firestore transaction, self-excluding the edited
  /// document from the Master LC consumption total.
  Future<Either<String, void>> updateWithTransaction(POEntity item);

  Future<Either<String, void>> createPO(POEntity item);
  Future<Either<String, void>> update(POEntity item);
  Future<Either<String, void>> delete(String id);
}


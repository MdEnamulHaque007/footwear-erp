import 'package:dartz/dartz.dart';
import '../entities/master_lc_entity.dart';
import '../../data/models/master_lc/master_lc_model.dart';

abstract interface class IMasterLCRepository {
  Future<Either<String, List<MasterLCModel>>> getMasterLCList({int page = 0, int limit = 20});
  Future<Either<String, MasterLCEntity?>> byTag(String tag);
  Future<Either<String, MasterLCEntity?>> byId(String id);

  /// Distinct Project / Company pairs seen across the saved Master LC records.
  /// Drives the form's predefined dropdowns (self-growing list).
  Future<Either<String, List<String>>> getProjectList();
  Future<Either<String, List<String>>> getCompanyList();

  /// Next available serial number (max stored `sl` + 1, or 1 when empty).
  ///
  /// SRS Rule 1 requires the Sl. to be auto-generated. The value returned here
  /// is a hint for display; the authoritative assignment happens inside
  /// [createWithTransaction], which increments a transactionally-guarded counter
  /// document so two concurrent creates can never receive the same Sl.
  Future<int> getMaxSl();

  /// Creates the Master LC inside a Firestore transaction (atomic write).
  Future<Either<String, void>> createWithTransaction(MasterLCEntity item);

  /// Updates the Master LC inside a Firestore transaction, re-checking the
  /// persisted document so a concurrent delete cannot be overwritten.
  Future<Either<String, void>> updateWithTransaction(MasterLCEntity item);

  Future<Either<String, void>> createMasterLC(MasterLCEntity item);
  Future<Either<String, void>> update(MasterLCEntity item);
  Future<Either<String, void>> delete(String id);
}


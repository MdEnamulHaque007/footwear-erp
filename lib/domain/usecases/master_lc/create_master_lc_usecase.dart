import 'package:dartz/dartz.dart';
import '../../entities/master_lc_entity.dart';
import '../../repositories/i_master_lc_repository.dart';

/// Creates a Master LC.
///
/// SRS Rule 1: the Sl. is auto-generated, so any caller-supplied value is
/// discarded and the repository assigns the next sequence number atomically
/// inside its create transaction.
class CreateMasterLCUseCase {
  CreateMasterLCUseCase(this._repository);
  final IMasterLCRepository _repository;

  Future<Either<String, void>> call(MasterLCEntity item) {
    // Always create with the "unassigned" sentinel; the repository replaces it
    // with the transactionally-allocated Sl.
    return _repository.createWithTransaction(item.copyWith(sl: 0));
  }
}

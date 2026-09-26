/// ============================================================================
/// ফাইল: lib/domain/usecases/master_lc/create_master_lc_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Master LC
/// উদ্দেশ্য: Master LC মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: CreateMasterLCUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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

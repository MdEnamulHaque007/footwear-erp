/// ============================================================================
/// ফাইল: lib/domain/usecases/sewing/create_sewing_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Sewing
/// উদ্দেশ্য: Sewing মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: CreateSewingUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../entities/sewing_entity.dart';
import '../../repositories/i_sewing_repository.dart';
import 'validate_sewing_quantity_usecase.dart';

/// Creates a Sewing entry.
///
/// PO-driven entries are written through [ISewingRepository.createWithTransaction]
/// so the cumulative Cutting / Sewing check and the write are atomic, which
/// keeps two concurrent devices from over-consuming the same Cutting quantity.
/// The pre-flight validation still runs first so the form gets a friendly
/// message without paying for a round-trip.
class CreateSewingUseCase {
  CreateSewingUseCase(this._repository, this._validate);
  final ISewingRepository _repository;
  final ValidateSewingQuantityUseCase _validate;

  Future<Either<String, void>> call(SewingEntity item) async {
    // Legacy entries without a PO line skip the chain validation.
    if (item.poNo.isNotEmpty) {
      final error = await _validate(
        poNo: item.poNo,
        article: item.article,
        color: item.color,
        candidateQuantity: item.effectiveQuantity,
        sewingDate: item.sewingDate,
      );
      if (error != null) return Left(error);
      return _repository.createWithTransaction(item);
    }
    return _repository.createSewing(item);
  }
}

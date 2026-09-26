/// ============================================================================
/// ফাইল: lib/domain/usecases/cutting/create_cutting_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Cutting
/// উদ্দেশ্য: Cutting মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: CreateCuttingUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../entities/cutting_entity.dart';
import '../../repositories/i_cutting_repository.dart';
import 'validate_cutting_quantity_usecase.dart';

/// Creates a Cutting entry after validating that its quantity is positive.
/// Cutting is a soft-limit stage: exceeding the PO balance is allowed and the
/// negative balance is retained for excess reporting.
class CreateCuttingUseCase {
  CreateCuttingUseCase(this._repository, [this._validate]);
  final ICuttingRepository _repository;
  final ValidateCuttingQuantityUseCase? _validate;

  Future<Either<String, void>> call(CuttingEntity item) async {
    if (_validate != null && item.poNo.isNotEmpty) {
      final validation = await _validate(
        poNo: item.poNo,
        article: item.article,
        color: item.color,
        poQuantity: item.poQuantity,
        candidateQuantity: item.cuttingQuantity,
        excludingId: item.id,
      );
      if (validation.isLeft()) {
        return validation.fold(Left.new, (_) => const Right(null));
      }
    }
    return _repository.createWithTransaction(item);
  }
}

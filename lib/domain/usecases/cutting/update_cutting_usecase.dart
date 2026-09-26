/// ============================================================================
/// ফাইল: lib/domain/usecases/cutting/update_cutting_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Cutting
/// উদ্দেশ্য: Cutting মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: UpdateCuttingUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../entities/cutting_entity.dart';
import '../../repositories/i_cutting_repository.dart';

/// Updates a Cutting entry. The repository retains the persisted Sl. and
/// self-excludes the edited document from the cumulative Cutting total.
class UpdateCuttingUseCase {
  UpdateCuttingUseCase(this._repository);
  final ICuttingRepository _repository;
  Future<Either<String, void>> call(CuttingEntity item) =>
      _repository.updateWithTransaction(item);
}

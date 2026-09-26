/// ============================================================================
/// ফাইল: lib/domain/usecases/cutting/get_cumulative_cutting_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Cutting
/// উদ্দেশ্য: Cutting মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GetCumulativeCuttingUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../repositories/i_cutting_repository.dart';

class GetCumulativeCuttingUseCase {
  GetCumulativeCuttingUseCase(this._repository);
  final ICuttingRepository _repository;
  Future<int> call({
    required String poNo,
    required String article,
    required String color,
    String? excludingId,
  }) => _repository.getCumulativeCuttingQuantityByLine(
    poNo: poNo,
    article: article,
    color: color,
    excludingId: excludingId,
  );
}

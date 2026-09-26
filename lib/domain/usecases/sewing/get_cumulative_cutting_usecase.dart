/// ============================================================================
/// ফাইল: lib/domain/usecases/sewing/get_cumulative_cutting_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Cutting
/// উদ্দেশ্য: Cutting মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GetCumulativeCuttingUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../repositories/i_sewing_repository.dart';

/// Cumulative Cutting quantity for a PO line (`poNo` + `article` + `color`)
/// counting only Cutting records dated on or before [upToDate] — i.e. the
/// quantity a Sewing entry dated [upToDate] may consume.
class GetCumulativeCuttingUseCase {
  GetCumulativeCuttingUseCase(this._repository);
  final ISewingRepository _repository;

  Future<Either<String, int>> call({
    required String poNo,
    required String article,
    required String color,
    required DateTime upToDate,
    String? excludeId,
  }) async {
    try {
      final quantity = await _repository.getCumulativeCuttingQty(
        poNo: poNo,
        article: article,
        color: color,
        upToDate: upToDate,
        excludingId: excludeId,
      );
      return Right(quantity);
    } catch (_) {
      return const Left('Unable to load cumulative cutting quantity');
    }
  }
}

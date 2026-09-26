/// ============================================================================
/// ফাইল: lib/domain/usecases/sewing/get_sewing_list_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Sewing
/// উদ্দেশ্য: Sewing মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GetSewingListUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../../data/models/sewing/sewing_model.dart';
import '../../repositories/i_sewing_repository.dart';

class GetSewingListUseCase {
  GetSewingListUseCase(this._repository);
  final ISewingRepository _repository;
  Future<Either<String, List<SewingModel>>> call({
    int page = 0,
    int limit = 20,
  }) => _repository.getSewingList(page: page, limit: limit);
}

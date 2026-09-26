/// ============================================================================
/// ফাইল: lib/domain/usecases/purchase_order/get_po_by_tag_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Purchase Order
/// উদ্দেশ্য: Purchase Order মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GetPOByTagUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../repositories/i_po_repository.dart';
import '../../../data/models/purchase_order/po_model.dart';

class GetPOByTagUseCase {
  GetPOByTagUseCase(this._repository);
  final IPORepository _repository;
  Future<Either<String, List<POModel>>> call(String tag) => _repository.byTag(tag);
}

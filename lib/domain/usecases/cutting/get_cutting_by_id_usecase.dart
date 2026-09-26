/// ============================================================================
/// ফাইল: lib/domain/usecases/cutting/get_cutting_by_id_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Cutting
/// উদ্দেশ্য: Cutting মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GetCuttingByIdUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../repositories/i_cutting_repository.dart';
import '../../../data/models/cutting/cutting_model.dart';

/// Loads a single Cutting record by document id (detail / edit screens).
class GetCuttingByIdUseCase {
  GetCuttingByIdUseCase(this._repository);
  final ICuttingRepository _repository;
  Future<Either<String, CuttingModel?>> call(String id) => _repository.byId(id);
}

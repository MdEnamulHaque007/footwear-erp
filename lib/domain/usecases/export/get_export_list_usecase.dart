/// ============================================================================
/// ফাইল: lib/domain/usecases/export/get_export_list_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Export
/// উদ্দেশ্য: Export মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GetExportListUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../repositories/i_export_repository.dart';
import '../../../data/models/export/export_model.dart';

class GetExportListUseCase {
  GetExportListUseCase(this._repository);
  final IExportRepository _repository;
  Future<Either<String, List<ExportModel>>> call({
    int page = 0,
    int limit = 20,
  }) => _repository.getExportList(page: page, limit: limit);
}

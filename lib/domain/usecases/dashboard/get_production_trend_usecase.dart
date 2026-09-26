/// ============================================================================
/// ফাইল: lib/domain/usecases/dashboard/get_production_trend_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Production/Lasting
/// উদ্দেশ্য: Production/Lasting মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GetProductionTrendUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../entities/dashboard/dashboard_chart_data_entity.dart';
import '../../repositories/i_dashboard_repository.dart';

class GetProductionTrendUseCase {
  GetProductionTrendUseCase(this._repository);
  final IDashboardRepository _repository;

  Future<Either<String, List<MultiSeriesDataPoint>>> call(int days) =>
      _repository.getProductionTrend(days);
}

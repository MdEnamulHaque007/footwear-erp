/// ============================================================================
/// ফাইল: lib/domain/usecases/dashboard/get_comparison_data_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GetComparisonDataUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../entities/dashboard/comparison_data_entity.dart';
import '../../repositories/i_dashboard_repository.dart';

/// Fetches one side of the department comparison.
///
/// The collection and field names come from the caller's `DepartmentOption`, so
/// any two stages of the production chain can be compared over independent date
/// ranges.
class GetComparisonDataUseCase {
  GetComparisonDataUseCase(this._repository);
  final IDashboardRepository _repository;

  Future<Either<String, ComparisonRangeEntity>> call({
    required String collection,
    required String dateField,
    required String quantityField,
    required DateTime fromDate,
    required DateTime toDate,
    required String label,
    required String department,
  }) => _repository.getComparisonData(
    collection: collection,
    dateField: dateField,
    quantityField: quantityField,
    fromDate: fromDate,
    toDate: toDate,
    label: label,
    department: department,
  );
}


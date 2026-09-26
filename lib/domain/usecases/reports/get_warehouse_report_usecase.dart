/// ============================================================================
/// ফাইল: lib/domain/usecases/reports/get_warehouse_report_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Reports
/// উদ্দেশ্য: Reports মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GetWarehouseReportUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';

import '../../entities/reports/warehouse_report_entity.dart';
import '../../repositories/i_warehouse_report_repository.dart';

class GetWarehouseReportUseCase {
  const GetWarehouseReportUseCase(this._repository);

  final IWarehouseReportRepository _repository;

  Future<Either<String, WarehouseReportResult>> call({
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    if (toDate.isBefore(fromDate)) {
      return Future.value(const Left('To date must be after From date'));
    }
    return _repository.getWarehouseReport(fromDate: fromDate, toDate: toDate);
  }
}

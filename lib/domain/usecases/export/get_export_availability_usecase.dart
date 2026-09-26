/// ============================================================================
/// ফাইল: lib/domain/usecases/export/get_export_availability_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Export
/// উদ্দেশ্য: Export মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GetExportAvailabilityUseCase, ExportAvailability
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../repositories/i_export_repository.dart';

/// Cumulative quantities behind an Export entry for one PO line: Issue
/// completed on or before [exportDate], the Export already recorded, and the
/// resulting available balance.
///
/// `available = issueQuantity − exportQuantity`
class GetExportAvailabilityUseCase {
  GetExportAvailabilityUseCase(this._repository);
  final IExportRepository _repository;

  Future<Either<String, ExportAvailability>> call({
    required String poNo,
    required String article,
    required String color,
    required DateTime exportDate,
    String? excludeId,
  }) async {
    try {
      final issue = await _repository.getCumulativeIssueQty(
        poNo: poNo,
        article: article,
        color: color,
        upToDate: exportDate,
      );
      final exported = await _repository.getCumulativeExportQty(
        poNo: poNo,
        article: article,
        color: color,
        excludeId: excludeId,
      );
      return Right(
        ExportAvailability(
          issueQuantity: issue,
          exportQuantity: exported,
          availableQuantity: (issue - exported).clamp(0, issue).toInt(),
        ),
      );
    } catch (_) {
      return const Left('Unable to load export availability');
    }
  }
}

/// Result of [GetExportAvailabilityUseCase].
class ExportAvailability {
  const ExportAvailability({
    required this.issueQuantity,
    required this.exportQuantity,
    required this.availableQuantity,
  });
  final int issueQuantity;
  final int exportQuantity;
  final int availableQuantity;
}

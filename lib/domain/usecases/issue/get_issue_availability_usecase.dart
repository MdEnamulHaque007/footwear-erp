/// ============================================================================
/// ফাইল: lib/domain/usecases/issue/get_issue_availability_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Finished Goods Issue
/// উদ্দেশ্য: Finished Goods Issue মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GetIssueAvailabilityUseCase, IssueAvailability
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../repositories/i_issue_repository.dart';

/// Cumulative quantities behind an Issue entry for one PO line: Production
/// completed on or before [issueDate], the Issue already recorded, and the
/// resulting available balance.
///
/// `available = productionQuantity − issueQuantity`
class GetIssueAvailabilityUseCase {
  GetIssueAvailabilityUseCase(this._repository);
  final IIssueRepository _repository;

  Future<Either<String, IssueAvailability>> call({
    required String poNo,
    required String article,
    required String color,
    required DateTime issueDate,
    String? excludeId,
  }) async {
    try {
      final production = await _repository.getCumulativeProductionQty(
        poNo: poNo,
        article: article,
        color: color,
        upToDate: issueDate,
      );
      final issued = await _repository.getCumulativeIssueQty(
        poNo: poNo,
        article: article,
        color: color,
        excludeId: excludeId,
      );
      return Right(
        IssueAvailability(
          productionQuantity: production,
          issueQuantity: issued,
          availableQuantity: (production - issued).clamp(0, production).toInt(),
        ),
      );
    } catch (_) {
      return const Left('Unable to load issue availability');
    }
  }
}

/// Result of [GetIssueAvailabilityUseCase].
class IssueAvailability {
  const IssueAvailability({
    required this.productionQuantity,
    required this.issueQuantity,
    required this.availableQuantity,
  });
  final int productionQuantity;
  final int issueQuantity;
  final int availableQuantity;
}

/// ============================================================================
/// ফাইল: lib/domain/usecases/issue/get_issue_article_colors_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Finished Goods Issue
/// উদ্দেশ্য: Finished Goods Issue মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GetIssueArticleColorsUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../entities/issue_entity.dart';
import '../../repositories/i_issue_repository.dart';

/// Distinct Article + Color pairs recorded in the Production entries of a PO.
///
/// Drives the Issue form's cascading dropdowns: a line can only be issued once
/// it has been produced.
class GetIssueArticleColorsUseCase {
  GetIssueArticleColorsUseCase(this._repository);
  final IIssueRepository _repository;

  Future<Either<String, List<ProductionLine>>> call(String poNo) =>
      _repository.getProductionEntryLines(poNo);
}

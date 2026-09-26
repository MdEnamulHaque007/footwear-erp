/// ============================================================================
/// ফাইল: lib/domain/usecases/issue/get_issue_list_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Finished Goods Issue
/// উদ্দেশ্য: Finished Goods Issue মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GetIssueListUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../../data/models/issue/issue_model.dart';
import '../../repositories/i_issue_repository.dart';

class GetIssueListUseCase {
  GetIssueListUseCase(this._repository);
  final IIssueRepository _repository;
  Future<Either<String, List<IssueModel>>> call({
    int page = 0,
    int limit = 20,
  }) => _repository.getIssueList(page: page, limit: limit);
}

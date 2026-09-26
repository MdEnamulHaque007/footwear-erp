/// ============================================================================
/// ফাইল: lib/domain/usecases/issue/create_issue_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Finished Goods Issue
/// উদ্দেশ্য: Finished Goods Issue মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: CreateIssueUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../entities/issue_entity.dart';
import '../../repositories/i_issue_repository.dart';
import 'validate_issue_quantity_usecase.dart';

class CreateIssueUseCase {
  CreateIssueUseCase(this._repository, this._validate);
  final IIssueRepository _repository;
  final ValidateIssueQuantityUseCase _validate;

  Future<Either<String, void>> call(IssueEntity item) async {
    if (item.poNo.isNotEmpty) {
      final error = await _validate(
        poTagNo: item.tagNo,
        issueDate: item.issueDate,
        candidateQuantity: item.quantity,
        poNo: item.poNo,
        article: item.article,
        color: item.color,
      );
      if (error != null) return Left(error);
      return _repository.createWithTransaction(item);
    }
    final error = await _validate(
      poTagNo: item.tagNo,
      issueDate: item.issueDate,
      candidateQuantity: item.quantity,
    );
    if (error != null) return Left(error);
    return _repository.createIssue(item);
  }
}

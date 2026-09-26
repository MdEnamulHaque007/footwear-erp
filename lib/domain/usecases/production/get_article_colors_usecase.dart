/// ============================================================================
/// ফাইল: lib/domain/usecases/production/get_article_colors_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Production/Lasting
/// উদ্দেশ্য: Production/Lasting মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GetArticleColorsUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
﻿import 'package:dartz/dartz.dart';
import '../../entities/production_entity.dart';
import '../../repositories/i_production_repository.dart';

/// Distinct Article + Color pairs recorded in the Sewing entries of a PO.
///
/// Drives the Production form's cascading dropdowns: a line can only be
/// produced once it has been sewn.
class GetArticleColorsUseCase {
  GetArticleColorsUseCase(this._repository);
  final IProductionRepository _repository;

  Future<Either<String, List<SewingLine>>> call(String poNo) =>
      _repository.getSewingEntryLines(poNo);
}

/// ============================================================================
/// ফাইল: lib/domain/usecases/settings/save_business_settings_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Settings
/// উদ্দেশ্য: Settings মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: SaveBusinessSettingsUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';

import '../../entities/settings/business_settings_entity.dart';
import '../../repositories/i_settings_repository.dart';

class SaveBusinessSettingsUseCase {
  SaveBusinessSettingsUseCase(this._repository);

  final ISettingsRepository _repository;

  Future<Either<String, void>> call(BusinessSettingsEntity entity) =>
      _repository.saveBusinessSettings(entity);
}

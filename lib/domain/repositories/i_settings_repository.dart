/// ============================================================================
/// ফাইল: lib/domain/repositories/i_settings_repository.dart
/// স্তর: Domain Repository Contract | মডিউল: Settings
/// উদ্দেশ্য: Settings data access-এর interface নির্ধারণ করে; implementation data layer-এ থাকে।
/// প্রধান অংশ: ISettingsRepository
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';

import '../entities/settings/app_settings_entity.dart';
import '../entities/settings/business_settings_entity.dart';

abstract class ISettingsRepository {
  Future<Either<String, AppSettingsEntity>> getAppSettings();

  Future<Either<String, void>> saveAppSettings(AppSettingsEntity entity);

  Future<Either<String, BusinessSettingsEntity>> getBusinessSettings();

  Future<Either<String, void>> saveBusinessSettings(
    BusinessSettingsEntity entity,
  );
}

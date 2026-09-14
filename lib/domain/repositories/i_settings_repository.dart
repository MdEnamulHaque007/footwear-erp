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

import 'package:dartz/dartz.dart';

import '../../entities/settings/app_settings_entity.dart';
import '../../repositories/i_settings_repository.dart';

class SaveAppSettingsUseCase {
  SaveAppSettingsUseCase(this._repository);

  final ISettingsRepository _repository;

  Future<Either<String, void>> call(AppSettingsEntity entity) =>
      _repository.saveAppSettings(entity);
}

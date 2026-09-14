import 'package:dartz/dartz.dart';

import '../../entities/settings/app_settings_entity.dart';
import '../../repositories/i_settings_repository.dart';

class GetAppSettingsUseCase {
  GetAppSettingsUseCase(this._repository);

  final ISettingsRepository _repository;

  Future<Either<String, AppSettingsEntity>> call() =>
      _repository.getAppSettings();
}

import 'package:dartz/dartz.dart';

import '../../entities/settings/business_settings_entity.dart';
import '../../repositories/i_settings_repository.dart';

class SaveBusinessSettingsUseCase {
  SaveBusinessSettingsUseCase(this._repository);

  final ISettingsRepository _repository;

  Future<Either<String, void>> call(BusinessSettingsEntity entity) =>
      _repository.saveBusinessSettings(entity);
}

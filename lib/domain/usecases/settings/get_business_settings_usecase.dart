import 'package:dartz/dartz.dart';

import '../../entities/settings/business_settings_entity.dart';
import '../../repositories/i_settings_repository.dart';

class GetBusinessSettingsUseCase {
  GetBusinessSettingsUseCase(this._repository);

  final ISettingsRepository _repository;

  Future<Either<String, BusinessSettingsEntity>> call() =>
      _repository.getBusinessSettings();
}

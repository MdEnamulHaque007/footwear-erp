import '../../entities/user_entity.dart';
import '../../repositories/i_auth_repository.dart';

class UpdateProfileUseCase {
  UpdateProfileUseCase(this._repository);

  final IAuthRepository _repository;

  Future<UserEntity> call(String displayName) {
    return _repository.updateDisplayName(displayName);
  }
}

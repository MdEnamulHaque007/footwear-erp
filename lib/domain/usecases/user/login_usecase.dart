import '../../entities/user_entity.dart';
import '../../repositories/i_auth_repository.dart';

class LoginUseCase {
  LoginUseCase(this._repository);
  final IAuthRepository _repository;
  Future<UserEntity> call(String email, String password) =>
      _repository.login(email, password);
}

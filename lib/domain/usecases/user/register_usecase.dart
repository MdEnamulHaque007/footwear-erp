import '../../entities/user_entity.dart';
import '../../repositories/i_auth_repository.dart';

class RegisterUseCase {
  RegisterUseCase(this._repository);
  final IAuthRepository _repository;
  Future<UserEntity> call(String name, String email, String password) =>
      _repository.register(name, email, password);
}

import '../../entities/user_entity.dart';
import '../../repositories/i_auth_repository.dart';

class CheckAuthStatusUseCase {
  CheckAuthStatusUseCase(this._repository);
  final IAuthRepository _repository;
  Future<UserEntity?> call() => _repository.getCurrentUser();
}

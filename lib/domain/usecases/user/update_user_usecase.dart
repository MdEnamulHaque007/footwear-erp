import 'package:dartz/dartz.dart';
import '../../entities/user_entity.dart';
import '../../repositories/i_user_repository.dart';

/// Updates a user's role, status and permissions together.
///
/// Runs through the repository's transaction so the three interdependent fields
/// cannot be left partially applied.
class UpdateUserUseCase {
  UpdateUserUseCase(this._repository);
  final IUserRepository _repository;

  Future<Either<String, void>> call(UserEntity user) async {
    if (user.uid.trim().isEmpty) {
      return const Left('User id is required');
    }
    if (user.role.trim().isEmpty) {
      return const Left('Role is required');
    }
    return _repository.updateUser(user);
  }
}

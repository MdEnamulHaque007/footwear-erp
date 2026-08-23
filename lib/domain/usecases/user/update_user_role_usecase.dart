import 'package:dartz/dartz.dart';
import '../../repositories/i_user_repository.dart';

class UpdateUserRoleUseCase {
  UpdateUserRoleUseCase(this._repository);
  final IUserRepository _repository;
  Future<Either<String, void>> call(String uid, String role) => _repository.updateUserRole(uid, role);
}

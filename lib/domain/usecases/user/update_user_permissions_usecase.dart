import 'package:dartz/dartz.dart';
import '../../repositories/i_user_repository.dart';

class UpdateUserPermissionsUseCase {
  UpdateUserPermissionsUseCase(this._repository);
  final IUserRepository _repository;
  Future<Either<String, void>> call(String uid, Map<String, dynamic> permissions) => _repository.updateUserPermissions(uid, permissions);
}

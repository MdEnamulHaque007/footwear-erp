import 'package:dartz/dartz.dart';
import '../../repositories/i_role_repository.dart';

class DeleteRoleUseCase {
  DeleteRoleUseCase(this._repository);
  final IRoleRepository _repository;
  Future<Either<String, void>> call(String roleId) => _repository.deleteRole(roleId);
}

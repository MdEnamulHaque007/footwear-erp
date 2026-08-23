import 'package:dartz/dartz.dart';
import '../../repositories/i_role_repository.dart';

class UpdateRolePermissionsUseCase {
  UpdateRolePermissionsUseCase(this._repository);
  final IRoleRepository _repository;
  Future<Either<String, void>> call(String roleId, Map<String, Map<String, bool>> permissions) => _repository.updateRolePermissions(roleId, permissions);
}

import '../../repositories/i_role_repository.dart';

class AssignPermissionToRoleUseCase {
  AssignPermissionToRoleUseCase(this._repository);
  final IRoleRepository _repository;
  Future<void> call(String id, Map<String, Map<String, bool>> permissions) =>
      _repository.updateRolePermissions(id, permissions);
}

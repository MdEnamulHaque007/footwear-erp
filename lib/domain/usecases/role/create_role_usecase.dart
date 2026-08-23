import 'package:dartz/dartz.dart';
import '../../entities/role_entity.dart';
import '../../repositories/i_role_repository.dart';

class CreateRoleUseCase {
  CreateRoleUseCase(this._repository);
  final IRoleRepository _repository;
  Future<Either<String, RoleEntity>> call(String name, Map<String, Map<String, bool>> permissions) => _repository.createRole(name, permissions);
}

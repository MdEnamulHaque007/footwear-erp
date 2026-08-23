import 'package:dartz/dartz.dart';
import '../entities/role_entity.dart';

abstract interface class IRoleRepository {
  Future<Either<String, List<RoleEntity>>> getAllRoles();
  Future<Either<String, RoleEntity>> createRole(String name, Map<String, Map<String, bool>> permissions);
  Future<Either<String, void>> updateRolePermissions(String roleId, Map<String, Map<String, bool>> permissions);
  Future<Either<String, void>> deleteRole(String roleId);
}

import 'package:dartz/dartz.dart';
import '../../entities/role_entity.dart';
import '../../repositories/i_role_repository.dart';

class GetAllRolesUseCase {
  GetAllRolesUseCase(this._repository);
  final IRoleRepository _repository;
  Future<Either<String, List<RoleEntity>>> call() => _repository.getAllRoles();
}

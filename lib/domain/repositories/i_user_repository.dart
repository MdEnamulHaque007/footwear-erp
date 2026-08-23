import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';

abstract interface class IUserRepository {
  Future<Either<String, List<UserEntity>>> getAllUsers({int page = 0, int limit = 20});
  Future<Either<String, void>> updateUserRole(String uid, String role);
  Future<Either<String, void>> updateUserPermissions(String uid, Map<String, dynamic> permissions);
  Future<Either<String, void>> updateUserStatus(String uid, bool isActive);
  Future<Either<String, void>> deleteUser(String uid);
}

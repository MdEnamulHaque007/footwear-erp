import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';

abstract interface class IUserRepository {
  Future<Either<String, List<UserEntity>>> getAllUsers({
    int page = 0,
    int limit = 20,
  });

  /// Loads a single profile by uid (detail / edit screens).
  Future<Either<String, UserEntity?>> byId(String uid);

  /// Writes role + status + permissions in one transaction.
  ///
  /// Bundling them keeps the three fields mutually consistent: a partial
  /// failure cannot leave a profile promoted without its permissions.
  Future<Either<String, void>> updateUser(UserEntity user);

  Future<Either<String, void>> updateUserRole(String uid, String role);
  Future<Either<String, void>> updateUserPermissions(
    String uid,
    Map<String, Map<String, bool>> permissions,
  );
  Future<Either<String, void>> updateUserStatus(String uid, bool isActive);
  Future<Either<String, void>> deleteUser(String uid);

  /// Creates the signed-in account's own `users/{uid}` profile as the first
  /// admin (initial setup only).
  ///
  /// Fails with a readable message once an admin profile already exists — the
  /// security rule permits this exactly once, while no admin is present.
  Future<Either<String, UserEntity>> bootstrapAdminProfile({
    required String displayName,
  });
}


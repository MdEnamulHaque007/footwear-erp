/// ============================================================================
/// ফাইল: lib/domain/repositories/i_user_repository.dart
/// স্তর: Domain Repository Contract | মডিউল: User Management
/// উদ্দেশ্য: User Management data access-এর interface নির্ধারণ করে; implementation data layer-এ থাকে।
/// প্রধান অংশ: top-level configuration ও helper declarations
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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


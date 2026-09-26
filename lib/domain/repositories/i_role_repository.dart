/// ============================================================================
/// ফাইল: lib/domain/repositories/i_role_repository.dart
/// স্তর: Domain Repository Contract | মডিউল: Role Management
/// উদ্দেশ্য: Role Management data access-এর interface নির্ধারণ করে; implementation data layer-এ থাকে।
/// প্রধান অংশ: top-level configuration ও helper declarations
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../entities/role_entity.dart';

abstract interface class IRoleRepository {
  Future<Either<String, List<RoleEntity>>> getAllRoles();
  Future<Either<String, RoleEntity>> createRole(String name, Map<String, Map<String, bool>> permissions);
  Future<Either<String, void>> updateRolePermissions(String roleId, Map<String, Map<String, bool>> permissions);
  Future<Either<String, void>> deleteRole(String roleId);
}

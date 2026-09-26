/// ============================================================================
/// ফাইল: lib/domain/entities/role_entity.dart
/// স্তর: Domain Entity | মডিউল: Role Management
/// উদ্দেশ্য: Role Management মডিউলের framework-independent business data ও হিসাবযোগ্য property সংজ্ঞায়িত করে।
/// প্রধান অংশ: RoleEntity
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
class RoleEntity {
  const RoleEntity({
    required this.roleId,
    required this.roleName,
    required this.permissions,
    this.createdAt,
    this.updatedAt,
  });
  final String roleId;
  final String roleName;
  final Map<String, Map<String, bool>> permissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

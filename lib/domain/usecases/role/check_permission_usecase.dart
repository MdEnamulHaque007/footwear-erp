/// ============================================================================
/// ফাইল: lib/domain/usecases/role/check_permission_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Role Management
/// উদ্দেশ্য: Role Management মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: CheckPermissionUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../../core/utils/permission_utils.dart';

class CheckPermissionUseCase {
  bool call(
    String role,
    Map<String, dynamic> permissions,
    String module,
    String action,
  ) => PermissionUtils.hasPermission(role, permissions, module, action);
}

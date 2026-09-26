/// ============================================================================
/// ফাইল: lib/core/utils/permission_utils.dart
/// স্তর: Core | মডিউল: ERP Common
/// উদ্দেশ্য: Permission Utils সম্পর্কিত shared configuration, utility, service বা application-wide behavior প্রদান করে।
/// প্রধান অংশ: PermissionUtils
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../constants/app_constants.dart';

class PermissionUtils {
  static bool hasPermission(
    String role,
    Map<String, dynamic> permissions,
    String module,
    String action,
  ) {
    if (role == AppConstants.roleAdmin) return true;
    final modulePermissions = permissions[module];
    if (modulePermissions is! Map) return false;
    return modulePermissions[action] == true;
  }

  static bool hasAnyPermission(
    String role,
    Map<String, dynamic> permissions,
    String module,
    Iterable<String> actions,
  ) =>
      actions.any((action) => hasPermission(role, permissions, module, action));
}

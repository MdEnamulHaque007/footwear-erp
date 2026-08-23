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

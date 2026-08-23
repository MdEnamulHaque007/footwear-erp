import '../../../core/utils/permission_utils.dart';

class CheckPermissionUseCase {
  bool call(
    String role,
    Map<String, dynamic> permissions,
    String module,
    String action,
  ) => PermissionUtils.hasPermission(role, permissions, module, action);
}

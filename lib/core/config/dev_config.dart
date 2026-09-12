import 'package:flutter/foundation.dart';

import '../../domain/entities/user_entity.dart';

/// Development-only authentication shortcuts (skip button + auto-login).
class DevConfig {
  const DevConfig._();

  static bool get enabled => kDebugMode;

  static const bool autoLogin = true;

  /// ✅ FIXED: Admin permissions added for all modules
  static const UserEntity devUser = UserEntity(
    uid: 'dev-user',
    email: 'dev@footwear.local',
    displayName: 'Developer',
    role: 'admin',
    isEmailVerified: true,
    isActive: true,
    permissions: {
      'master_lc': {'view': true, 'create': true, 'edit': true, 'delete': true},
      'purchase_order': {
        'view': true,
        'create': true,
        'edit': true,
        'delete': true,
      },
      'cutting': {'view': true, 'create': true, 'edit': true, 'delete': true},
      'sewing': {'view': true, 'create': true, 'edit': true, 'delete': true},
      'production': {
        'view': true,
        'create': true,
        'edit': true,
        'delete': true,
      },
      'issue': {'view': true, 'create': true, 'edit': true, 'delete': true},
      'export': {'view': true, 'create': true, 'edit': true, 'delete': true},
      'user_management': {
        'view': true,
        'create': true,
        'edit': true,
        'delete': true,
      },
      'role_management': {
        'view': true,
        'create': true,
        'edit': true,
        'delete': true,
      },
      'audit_log': {'view': true, 'create': true, 'edit': true, 'delete': true},
      'reports': {'view': true, 'create': true, 'edit': true, 'delete': true},
    },
  );
}

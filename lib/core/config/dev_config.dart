import 'package:flutter/foundation.dart';

import '../../domain/entities/user_entity.dart';

/// Development-only authentication shortcuts (auth bypass, skip button,
/// auto-login and local emulator wiring).
///
/// 🔴 DEBUG ONLY — every switch below is hard-gated on [kDebugMode], which is
/// `false` in profile/release builds, so a shipped app **always** enforces real
/// Firebase authentication. Nothing here can leak into production.
///
/// | Command                                                | Effect                      |
/// | ------------------------------------------------------ | --------------------------- |
/// | `flutter run`                                          | real Firebase login flow    |
/// | `flutter run --dart-define=ENABLE_AUTH=false`           | debug admin bypass          |
/// | `flutter run --dart-define=USE_FIREBASE_EMULATOR=true`  | real auth + local emulators |
/// | `flutter build web --release`                           | real login flow             |
class DevConfig {
  const DevConfig._();

  /// Defaults to the real Firebase login flow in every build. Set
  /// `--dart-define=ENABLE_AUTH=false` only for an explicit debug bypass.
  static const bool enableAuth = bool.fromEnvironment(
    'ENABLE_AUTH',
    defaultValue: true,
  );

  /// True when a debug build may skip authentication completely: [AuthBloc]
  /// emits [devUser] and [RouteGuard] lets every route through, without ever
  /// touching Firebase Auth or the Firestore user profile.
  ///
  /// 🔴 Always `false` in profile/release builds (gated on [kDebugMode]).
  static bool get bypassAuth => kDebugMode && !enableAuth;

  /// Keeps the explicit "Skip login (dev)" flow available when bypass is
  /// deliberately enabled in a debug build.
  static const bool autoLogin = true;

  /// `--dart-define=USE_FIREBASE_EMULATOR=true` points Auth + Firestore at the
  /// local emulator suite started with `firebase emulators:start`, so a
  /// bypassed app can read/write data **without opening the production
  /// security rules**.
  static const bool _emulatorFlag = bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: false,
  );

  /// Emulator host. Use `10.0.2.2` from an Android emulator:
  /// `--dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2`.
  static const String emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: 'localhost',
  );

  static const int authEmulatorPort = 9099;
  static const int firestoreEmulatorPort = 8080;

  /// 🔴 Always `false` in profile/release builds (gated on [kDebugMode]).
  static bool get useFirebaseEmulator => kDebugMode && _emulatorFlag;

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

import 'package:flutter/foundation.dart';

import '../../domain/entities/user_entity.dart';

/// Development-only authentication shortcuts (skip button + auto-login).
///
/// Everything here is gated by [kDebugMode], so it is tree-shaken out of
/// profile/release builds and can never activate in production.
///
/// IMPORTANT: [devUser] is a *client-side mock*. It does NOT create a Firebase
/// Auth session, so any Firestore read/write that requires authentication will
/// be denied by the security rules (`request.auth` is null). This is fine for
/// navigating the UI without logging in, but data-backed screens (Master LC,
/// PO, user/role management, dashboard stats) will come back empty or with a
/// permission error. Use real credentials when you need real data.
class DevConfig {
  const DevConfig._();

  /// Master switch: dev auth shortcuts only exist in debug builds.
  static bool get enabled => kDebugMode;

  /// When true (debug only), the app auto-authenticates as [devUser] on
  /// startup so the login screen is skipped. Set to `false` to exercise the
  /// real login flow in debug while still keeping the "Skip login" button.
  static const bool autoLogin = true;

  /// The in-memory developer account used by auto-login and the skip button.
  /// `role: 'admin'` unlocks every route (including `/admin`) during dev.
  static const UserEntity devUser = UserEntity(
    uid: 'dev-user',
    email: 'dev@footwear.local',
    displayName: 'Developer',
    role: 'admin',
    permissions: <String, bool>{},
    isEmailVerified: true,
    isActive: true,
  );
}

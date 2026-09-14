import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/core/config/dev_config.dart';

/// Covers the debug-only authentication bypass documented in
/// `lib/core/config/dev_config.dart`.
///
/// `flutter test` runs in debug mode with no `--dart-define`, but real Firebase
/// authentication remains the default. The bypass is available only when
/// `--dart-define=ENABLE_AUTH=false` is explicitly supplied.
void main() {
  group('DevConfig.bypassAuth', () {
    test('is gated on kDebugMode and the ENABLE_AUTH dart-define', () {
      expect(DevConfig.bypassAuth, kDebugMode && !DevConfig.enableAuth);
    });

    test('is disabled for a default run', () {
      expect(DevConfig.enableAuth, isTrue);
      expect(DevConfig.bypassAuth, isFalse);
    });

    test('is never available outside a debug build', () {
      // `kDebugMode` is the only gate that can lift the bypass, so a release or
      // profile build always keeps the real Firebase login flow.
      if (!kDebugMode) {
        expect(DevConfig.bypassAuth, isFalse);
      }
    });
  });

  group('DevConfig emulator wiring', () {
    test('stays off unless USE_FIREBASE_EMULATOR is set', () {
      expect(DevConfig.useFirebaseEmulator, isFalse);
    });

    test('uses the standard emulator suite endpoints', () {
      expect(DevConfig.emulatorHost, 'localhost');
      expect(DevConfig.authEmulatorPort, 9099);
      expect(DevConfig.firestoreEmulatorPort, 8080);
    });
  });

  group('DevConfig.devUser', () {
    test('is an active, verified admin', () {
      final user = DevConfig.devUser;
      expect(user.uid, 'dev-user');
      expect(user.email, 'dev@footwear.local');
      expect(user.role, 'admin');
      expect(user.isActive, isTrue);
      expect(user.isEmailVerified, isTrue);
    });

    test('has view/create/edit/delete on every module', () {
      const modules = [
        'master_lc',
        'purchase_order',
        'cutting',
        'sewing',
        'production',
        'issue',
        'export',
        'user_management',
        'role_management',
        'audit_log',
        'reports',
      ];
      for (final module in modules) {
        for (final action in ['view', 'create', 'edit', 'delete']) {
          expect(
            DevConfig.devUser.hasPermission(module, action),
            isTrue,
            reason: 'dev user should have $module.$action',
          );
        }
      }
    });
  });
}

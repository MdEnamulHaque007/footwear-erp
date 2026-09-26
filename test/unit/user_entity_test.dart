/// ============================================================================
/// ফাইল: test/unit/user_entity_test.dart
/// স্তর: Test | মডিউল: User Management
/// উদ্দেশ্য: User Entity Test অংশের প্রত্যাশিত আচরণ স্বয়ংক্রিয়ভাবে যাচাই করে এবং regression প্রতিরোধ করে।
/// প্রধান অংশ: top-level configuration ও helper declarations
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/core/constants/app_constants.dart';
import 'package:footwear/domain/entities/user_entity.dart';

UserEntity _user({
  String role = 'viewer',
  Map<String, Map<String, bool>>? permissions,
  String displayName = 'Test User',
  String email = 'test@example.com',
}) => UserEntity(
  uid: 'uid-1',
  email: email,
  displayName: displayName,
  role: role,
  permissions: permissions,
  isEmailVerified: false,
  isActive: true,
);

void main() {
  group('UserEntity roles', () {
    test('exposes role getters', () {
      expect(_user(role: 'admin').isAdmin, isTrue);
      expect(_user(role: 'editor').isEditor, isTrue);
      expect(_user(role: 'viewer').isViewer, isTrue);
      expect(_user(role: 'viewer').isAdmin, isFalse);
    });

    test('every assignable role is one of the three known roles', () {
      expect(AppConstants.assignableRoles, containsAll(['admin', 'editor']));
      expect(AppConstants.assignableRoles, contains('viewer'));
    });
  });

  group('UserEntity.displayLabel', () {
    test('prefers the display name', () {
      expect(_user(displayName: 'Alice').displayLabel, 'Alice');
    });

    test('falls back to the email when the name is blank', () {
      final user = _user(displayName: '');
      expect(user.displayLabel, 'test@example.com');
    });
  });

  group('UserEntity.hasPermission', () {
    test('an admin implicitly holds every permission', () {
      final admin = _user(role: 'admin');
      expect(admin.hasPermission(AppConstants.moduleCutting, 'delete'), isTrue);
      expect(admin.hasPermission('anything', 'anything'), isTrue);
    });

    test('a viewer only holds granted permissions', () {
      final viewer = _user(
        permissions: {
          AppConstants.moduleCutting: {'view': true, 'edit': false},
        },
      );
      expect(viewer.hasPermission(AppConstants.moduleCutting, 'view'), isTrue);
      expect(viewer.hasPermission(AppConstants.moduleCutting, 'edit'), isFalse);
      expect(viewer.hasPermission(AppConstants.moduleSewing, 'view'), isFalse);
    });

    test('missing permissions map denies rather than throws', () {
      expect(
        _user(permissions: null).hasPermission('cutting', 'view'),
        isFalse,
      );
    });
  });

  group('UserEntity.copyWith', () {
    test('replaces only the provided fields', () {
      final user = _user(displayName: 'Alice', role: 'viewer');
      final updated = user.copyWith(role: 'editor', isActive: false);
      expect(updated.role, 'editor');
      expect(updated.isActive, isFalse);
      expect(updated.displayName, 'Alice');
      expect(updated.uid, 'uid-1');
    });

    test('can clear permissions by passing an explicit value', () {
      final user = _user(
        permissions: {
          'cutting': {'view': true},
        },
      );
      expect(user.copyWith(permissions: null).permissions, isNull);
    });
  });
}

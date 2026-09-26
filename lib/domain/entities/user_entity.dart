/// ============================================================================
/// ফাইল: lib/domain/entities/user_entity.dart
/// স্তর: Domain Entity | মডিউল: User Management
/// উদ্দেশ্য: User Management মডিউলের framework-independent business data ও হিসাবযোগ্য property সংজ্ঞায়িত করে।
/// প্রধান অংশ: UserEntity
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
class UserEntity {
  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.permissions,
    required this.isEmailVerified,
    required this.isActive,
    this.lastLogin,
    this.createdAt,
    this.photoUrl,
    this.source,
    this.syncStatus,
  });

  final String uid;
  final String email;
  final String displayName;
  final String role;

  /// Module → action → granted, e.g. `{'cutting': {'view': true}}`.
  final Map<String, Map<String, bool>>? permissions;
  final bool isEmailVerified;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final String? photoUrl;

  /// Origin of the profile: `manual` (app) or `google_sheets` (import).
  final String? source;

  /// Sync state of imported profiles, e.g. `synced`.
  final String? syncStatus;

  bool get isAdmin => role == 'admin';
  bool get isEditor => role == 'editor';
  bool get isViewer => role == 'viewer';

  /// Name to show in tables: the display name, falling back to the email.
  String get displayLabel => displayName.isNotEmpty ? displayName : email;

  /// Role-aware permission check. Admins implicitly hold every permission.
  bool hasPermission(String module, String action) {
    if (isAdmin) return true;
    return permissions?[module]?[action] ?? false;
  }

  /// Returns a copy with the provided fields replaced.
  ///
  /// Nullable fields ([permissions], [lastLogin], [createdAt], [photoUrl]) use a
  /// sentinel so they can be explicitly **cleared** by passing `null`; a plain
  /// `??` would silently keep the old value and make "revoke all permissions"
  /// impossible.
  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    Object? permissions = _unset,
    bool? isEmailVerified,
    bool? isActive,
    Object? lastLogin = _unset,
    Object? createdAt = _unset,
    Object? photoUrl = _unset,
    String? source,
    String? syncStatus,
  }) => UserEntity(
    uid: uid ?? this.uid,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    role: role ?? this.role,
    permissions: permissions == _unset
        ? this.permissions
        : permissions as Map<String, Map<String, bool>>?,
    isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    isActive: isActive ?? this.isActive,
    lastLogin: lastLogin == _unset ? this.lastLogin : lastLogin as DateTime?,
    createdAt: createdAt == _unset ? this.createdAt : createdAt as DateTime?,
    photoUrl: photoUrl == _unset ? this.photoUrl : photoUrl as String?,
    source: source ?? this.source,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}

/// Sentinel distinguishing "argument omitted" from "explicitly passed null".
const Object _unset = Object();

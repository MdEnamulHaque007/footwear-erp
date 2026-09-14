import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    required super.role,
    super.permissions,
    required super.isEmailVerified,
    required super.isActive,
    super.lastLogin,
    super.createdAt,
    super.photoUrl,
    super.source,
    super.syncStatus,
  });

  factory UserModel.fromEntity(UserEntity e) => UserModel(
    uid: e.uid,
    email: e.email,
    displayName: e.displayName,
    role: e.role,
    permissions: e.permissions,
    isEmailVerified: e.isEmailVerified,
    isActive: e.isActive,
    lastLogin: e.lastLogin,
    createdAt: e.createdAt,
    photoUrl: e.photoUrl,
    source: e.source,
    syncStatus: e.syncStatus,
  );

  /// Builds a model from a Firebase Auth user combined with an optional
  /// Firestore profile.
  ///
  /// When [data] is `null` the account has no usable profile, so `role` is left
  /// **empty** rather than defaulting to `'viewer'`. The empty role is the
  /// signal [RouteGuard] uses to divert the account to the one-time
  /// administrator bootstrap; defaulting to a real role here would instead
  /// present a signed-in-looking app in which every Firestore rule denies.
  factory UserModel.fromFirebase(User user, Map<String, dynamic>? data) {
    final profile = data ?? const <String, dynamic>{};
    final hasProfile = data != null;
    return UserModel(
      uid: user.uid,
      email: _string(user.email ?? profile['email']),
      displayName: _string(user.displayName ?? profile['displayName']),
      role: hasProfile
          ? _string(profile['role'], fallback: 'viewer')
          : '',
      permissions: _permissions(profile['permissions']),
      isEmailVerified: user.emailVerified || _bool(profile['isEmailVerified']),
      isActive: hasProfile ? _bool(profile['isActive'], fallback: true) : false,
      lastLogin: _date(profile['lastLogin']),
      createdAt: _date(profile['createdAt']),
      photoUrl: _nullableString(user.photoURL ?? profile['photoUrl']),
      source: _nullableString(profile['source']),
      syncStatus: _nullableString(profile['syncStatus']),
    );
  }

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return UserModel(
      // Fall back to the document id when the profile has no `uid` field.
      uid: _string(data['uid'], fallback: snapshot.id),
      email: _string(data['email']),
      displayName: _string(data['displayName']),
      role: _string(data['role'], fallback: 'viewer'),
      permissions: _permissions(data['permissions']),
      isEmailVerified: _bool(data['isEmailVerified']),
      isActive: _bool(data['isActive'], fallback: true),
      lastLogin: _date(data['lastLogin']),
      createdAt: _date(data['createdAt']),
      photoUrl: _nullableString(data['photoUrl']),
      source: _nullableString(data['source']),
      syncStatus: _nullableString(data['syncStatus']),
    );
  }

  /// Parses the nested `{module: {action: bool}}` permission map defensively.
  ///
  /// Legacy profiles store the inner flags as strings/numbers, so each value is
  /// coerced rather than cast.
  static Map<String, Map<String, bool>>? _permissions(Object? json) {
    if (json is! Map) return null;
    final parsed = <String, Map<String, bool>>{};
    for (final entry in json.entries) {
      final module = entry.key.toString().trim();
      if (module.isEmpty) continue;
      final actions = entry.value;
      if (actions is! Map) continue;
      final flags = <String, bool>{};
      for (final action in actions.entries) {
        final key = action.key.toString().trim();
        if (key.isEmpty) continue;
        flags[key] = _bool(action.value);
      }
      if (flags.isNotEmpty) parsed[module] = flags;
    }
    return parsed.isEmpty ? null : parsed;
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'role': role,
    'permissions': permissions,
    'isEmailVerified': isEmailVerified,
    'isActive': isActive,
    'lastLogin': lastLogin == null ? null : Timestamp.fromDate(lastLogin!),
    'createdAt': createdAt == null
        ? Timestamp.now()
        : Timestamp.fromDate(createdAt!),
    'photoUrl': photoUrl,
    'source': source ?? 'manual',
    'syncStatus': syncStatus ?? 'synced',
  };

  UserEntity toEntity() => UserEntity(
    uid: uid,
    email: email,
    displayName: displayName,
    role: role,
    permissions: permissions,
    isEmailVerified: isEmailVerified,
    isActive: isActive,
    lastLogin: lastLogin,
    createdAt: createdAt,
    photoUrl: photoUrl,
    source: source,
    syncStatus: syncStatus,
  );

  /// Coerces any Firestore value to non-null text.
  static String _string(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  /// Coerces booleans, and the `'true'` / `1` forms legacy rows may carry.
  static bool _bool(Object? value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return fallback;
  }

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

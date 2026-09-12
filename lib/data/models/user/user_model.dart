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
  });

  factory UserModel.fromFirebase(User user, Map<String, dynamic>? data) {
    final profile = data ?? const <String, dynamic>{};
    return UserModel(
      uid: user.uid,
      email: user.email ?? (profile['email'] as String? ?? ''),
      displayName:
          user.displayName ?? (profile['displayName'] as String? ?? ''),
      role: profile['role'] as String? ?? 'viewer',
      permissions: _permissionsFromJson(profile['permissions']),
      isEmailVerified: user.emailVerified,
      isActive: profile['isActive'] as bool? ?? true,
      lastLogin: _date(profile['lastLogin']),
      createdAt: _date(profile['createdAt']),
    );
  }

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return UserModel(
      uid: data['uid'] as String? ?? snapshot.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: data['role'] as String? ?? 'viewer',
      permissions: _permissionsFromJson(data['permissions']),
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      lastLogin: _date(data['lastLogin']),
      createdAt: _date(data['createdAt']),
    );
  }

  static Map<String, Map<String, bool>>? _permissionsFromJson(dynamic json) {
    if (json == null || json is! Map) return null;
    return json.map(
      (key, value) => MapEntry(
        key.toString(),
        Map<String, bool>.from(
          (value is Map ? value : {}).map(
            (k, v) => MapEntry(k.toString(), v == true),
          ),
        ),
      ),
    );
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
    'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
  };

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

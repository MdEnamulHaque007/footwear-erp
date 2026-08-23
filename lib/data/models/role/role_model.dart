import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/role_entity.dart';

class RoleModel extends RoleEntity {
  const RoleModel({
    required super.roleId,
    required super.roleName,
    required super.permissions,
    super.createdAt,
    super.updatedAt,
  });

  factory RoleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    final raw = data['permissions'] as Map? ?? {};
    return RoleModel(
      roleId: data['roleId'] as String? ?? snapshot.id,
      roleName: data['roleName'] as String? ?? snapshot.id,
      permissions: raw.map(
        (key, value) => MapEntry(
          key.toString(),
          Map<String, bool>.from(value as Map? ?? {}),
        ),
      ),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'roleId': roleId,
    'roleName': roleName,
    'permissions': permissions,
    'createdAt': createdAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(createdAt!),
    'updatedAt': updatedAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(updatedAt!),
  };

  static DateTime? _date(Object? value) =>
      value is Timestamp ? value.toDate() : null;
}

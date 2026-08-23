class RoleEntity {
  const RoleEntity({
    required this.roleId,
    required this.roleName,
    required this.permissions,
    this.createdAt,
    this.updatedAt,
  });
  final String roleId;
  final String roleName;
  final Map<String, Map<String, bool>> permissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

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
  });

  final String uid;
  final String email;
  final String displayName;
  final String role;
  final Map<String, Map<String, bool>>? permissions;
  final bool isEmailVerified;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime? createdAt;

  bool hasPermission(String module, String action) {
    if (role == 'admin') return true;
    return permissions?[module]?[action] ?? false;
  }
}

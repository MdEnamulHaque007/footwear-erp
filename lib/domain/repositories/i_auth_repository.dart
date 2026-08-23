import '../entities/user_entity.dart';

abstract interface class IAuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register(String name, String email, String password);
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Future<void> resetPassword(String email);
  Stream<UserEntity?> get authStateChanges;
}

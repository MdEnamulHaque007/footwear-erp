import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/remote/auth_remote_datasource.dart';

class AuthRepository implements IAuthRepository {
  AuthRepository(this._dataSource);
  final AuthRemoteDataSource _dataSource;

  @override
  Future<UserEntity> login(String email, String password) =>
      _dataSource.login(email, password);

  @override
  Future<UserEntity> register(String name, String email, String password) =>
      _dataSource.register(name, email, password);

  @override
  Future<void> logout() => _dataSource.logout();

  @override
  Future<UserEntity?> getCurrentUser() => _dataSource.currentUser();

  @override
  Future<void> resetPassword(String email) => _dataSource.resetPassword(email);

  @override
  Future<UserEntity> updateDisplayName(String displayName) =>
      _dataSource.updateDisplayName(displayName);

  @override
  Stream<UserEntity?> get authStateChanges => _dataSource.authStateChanges;

  static String messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password';
      case 'email-already-in-use':
        return 'An account already exists for this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Enter a valid email address';
      default:
        return error.message ?? 'Authentication failed';
    }
  }
}

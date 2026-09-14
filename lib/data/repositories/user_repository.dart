import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../core/config/dev_config.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user/user_model.dart';

class UserRepository implements IUserRepository {
  UserRepository({
    FirebaseFirestore? firestore,
    AuthRemoteDataSource? authDataSource,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _authDataSource = authDataSource ?? AuthRemoteDataSource();
  final FirebaseFirestore _firestore;
  final AuthRemoteDataSource _authDataSource;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  final List<UserEntity> _devUsers = [DevConfig.devUser];

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.collectionUsers);

  @override
  Future<Either<String, List<UserEntity>>> getAllUsers({
    int page = 0,
    int limit = 20,
  }) async {
    if (DevConfig.bypassAuth) {
      final start = page * limit;
      if (start >= _devUsers.length) return const Right([]);
      final end = start + limit > _devUsers.length
          ? _devUsers.length
          : start + limit;
      return Right(_devUsers.sublist(start, end));
    }
    try {
      if (page == 0) _lastDoc = null;
      Query<Map<String, dynamic>> query = _collection.orderBy(
        FieldPath.documentId,
      );
      if (page > 0 && _lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      final snapshot = await query.limit(limit).get();
      if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;
      final users = snapshot.docs.map(UserModel.fromFirestore).toList();
      return Right(users);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Loads a single profile by uid.
  @override
  Future<Either<String, UserEntity?>> byId(String uid) async {
    if (DevConfig.bypassAuth) {
      for (final user in _devUsers) {
        if (user.uid == uid) return Right(user);
      }
      return const Right(null);
    }
    try {
      final snapshot = await _collection.doc(uid).get();
      if (!snapshot.exists) return const Right(null);
      return Right(UserModel.fromFirestore(snapshot).toEntity());
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Writes role, status and permissions as one atomic transaction.
  ///
  /// The three fields are interdependent (an admin implicitly holds every
  /// permission, a viewer's are explicit), so a partial write would leave the
  /// profile in a state that neither the UI nor the Firestore rules expect.
  @override
  Future<Either<String, void>> updateUser(UserEntity user) async {
    if (DevConfig.bypassAuth) {
      return _replaceDevUser(user.uid, (_) => user);
    }
    try {
      final ref = _collection.doc(user.uid);
      final payload = UserModel.fromEntity(user).toFirestore()
        ..remove('uid')
        ..remove('createdAt');
      await _firestore.runTransaction<void>((transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) {
          throw const _UserUpdateException('User no longer exists');
        }
        transaction.update(ref, payload);
      });
      return const Right(null);
    } on _UserUpdateException catch (e) {
      return Left(e.message);
    } on FirebaseException catch (e) {
      return Left('Update failed: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> updateUserRole(String uid, String role) async {
    if (DevConfig.bypassAuth) {
      return _replaceDevUser(uid, (user) => user.copyWith(role: role));
    }
    try {
      await _collection.doc(uid).update({'role': role});
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left('Update failed: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> updateUserPermissions(
    String uid,
    Map<String, Map<String, bool>> permissions,
  ) async {
    if (DevConfig.bypassAuth) {
      return _replaceDevUser(
        uid,
        (user) => user.copyWith(permissions: permissions),
      );
    }
    try {
      await _collection.doc(uid).update({'permissions': permissions});
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left('Update failed: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> updateUserStatus(
    String uid,
    bool isActive,
  ) async {
    if (DevConfig.bypassAuth) {
      return _replaceDevUser(uid, (user) => user.copyWith(isActive: isActive));
    }
    try {
      await _collection.doc(uid).update({'isActive': isActive});
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left('Update failed: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> deleteUser(String uid) async {
    if (DevConfig.bypassAuth) {
      if (uid == DevConfig.devUser.uid) {
        return const Left('The debug administrator cannot be deleted');
      }
      _devUsers.removeWhere((user) => user.uid == uid);
      return const Right(null);
    }
    try {
      await _collection.doc(uid).delete();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left('Delete failed: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Creates the signed-in account's own profile as the first admin.
  ///
  /// Delegates to [AuthRemoteDataSource.bootstrapAdminProfile], which writes the
  /// transient `bootstrap: true` flag the security rule requires and then clears
  /// it. In debug bypass there is no Firebase Auth session, so the in-memory dev
  /// admin is returned instead of touching Firestore.
  @override
  Future<Either<String, UserEntity>> bootstrapAdminProfile({
    required String displayName,
  }) async {
    if (DevConfig.bypassAuth) {
      return Right(
        DevConfig.devUser.copyWith(displayName: displayName.trim()),
      );
    }
    final result = await _authDataSource.bootstrapAdminProfile(
      displayName: displayName,
    );
    return result.map((model) => model.toEntity());
  }

  Either<String, void> _replaceDevUser(
    String uid,
    UserEntity Function(UserEntity user) update,
  ) {
    final index = _devUsers.indexWhere((user) => user.uid == uid);
    if (index == -1) return const Left('User not found');
    _devUsers[index] = update(_devUsers[index]);
    return const Right(null);
  }
}

/// Signals a business-rule failure inside [UserRepository.updateUser]'s
/// transaction, so it can be surfaced verbatim instead of as a generic error.
class _UserUpdateException implements Exception {
  const _UserUpdateException(this.message);
  final String message;

  @override
  String toString() => message;
}

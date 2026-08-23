import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../models/user/user_model.dart';

class UserRepository implements IUserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;
  
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.collectionUsers);
      
  @override
  Future<Either<String, List<UserEntity>>> getAllUsers({int page = 0, int limit = 20}) async {
    try {
      final snapshot = await _collection.limit(limit).get();
      final users = snapshot.docs.map(UserModel.fromFirestore).toList();
      return Right(users);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }
  
  @override
  Future<Either<String, void>> updateUserRole(String uid, String role) async {
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
    Map<String, dynamic> permissions,
  ) async {
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
  Future<Either<String, void>> updateUserStatus(String uid, bool isActive) async {
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
    try {
      await _collection.doc(uid).delete();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left('Delete failed: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/repositories/i_role_repository.dart';
import '../models/role/role_model.dart';

class RoleRepository implements IRoleRepository {
  RoleRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  @override
  Future<Either<String, List<RoleEntity>>> getAllRoles() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionRoles)
          .get();
      final roles = snapshot.docs.map(RoleModel.fromFirestore).toList();
      return Right(roles);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, RoleEntity>> createRole(
    String name,
    Map<String, Map<String, bool>> permissions,
  ) async {
    try {
      final ref = _firestore.collection(AppConstants.collectionRoles).doc();
      final model = RoleModel(
        roleId: ref.id,
        roleName: name.trim(),
        permissions: permissions,
      );
      await ref.set(model.toFirestore());
      return Right(model);
    } on FirebaseException catch (e) {
      return Left('Failed to create role: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> updateRolePermissions(
    String roleId,
    Map<String, Map<String, bool>> permissions,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.collectionRoles)
          .doc(roleId)
          .update({
            'permissions': permissions,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left('Update failed: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> deleteRole(String roleId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionRoles)
          .doc(roleId)
          .delete();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left('Delete failed: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }
}

/// ============================================================================
/// ফাইল: lib/data/repositories/role_repository.dart
/// স্তর: Data Repository | মডিউল: Role Management
/// উদ্দেশ্য: Role Management data query, transaction, pagination ও persistence বাস্তবায়ন করে।
/// প্রধান অংশ: RoleRepository
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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
          .limit(20)
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

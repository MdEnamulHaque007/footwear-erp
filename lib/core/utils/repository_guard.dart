import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

/// Wraps a Firestore-backed repository operation in the standard
/// try / FirebaseException / catch error-handling boilerplate.
///
/// Returns [Right] with the operation result, or [Left] with a
/// user-friendly error message prefixed by [prefix] (e.g. 'Failed to create').
extension RepositoryGuard on Object {
  Future<Either<String, T>> guard<T>(
    Future<T> Function() operation, {
    String prefix = 'Database error',
  }) async {
    try {
      final result = await operation();
      return Right(result);
    } on FirebaseException catch (e) {
      return Left('$prefix: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }
}

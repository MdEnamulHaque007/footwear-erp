/// ============================================================================
/// ফাইল: lib/core/utils/repository_guard.dart
/// স্তর: Core | মডিউল: ERP Common
/// উদ্দেশ্য: Repository Guard সম্পর্কিত shared configuration, utility, service বা application-wide behavior প্রদান করে।
/// প্রধান অংশ: RepositoryGuard
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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

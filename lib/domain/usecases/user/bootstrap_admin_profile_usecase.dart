/// ============================================================================
/// ফাইল: lib/domain/usecases/user/bootstrap_admin_profile_usecase.dart
/// স্তর: Domain Use Case | মডিউল: User Management
/// উদ্দেশ্য: User Management মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: BootstrapAdminProfileUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../entities/user_entity.dart';
import '../../repositories/i_user_repository.dart';

/// Creates the signed-in account's own `users/{uid}` profile as the first
/// admin, for initial project setup.
///
/// The Firestore rule that backs this permits the write only while no admin
/// profile exists, so it succeeds exactly once. Any later attempt comes back as
/// a [Left] with an explanatory message.
class BootstrapAdminProfileUseCase {
  BootstrapAdminProfileUseCase(this._repository);
  final IUserRepository _repository;

  Future<Either<String, UserEntity>> call({required String displayName}) =>
      _repository.bootstrapAdminProfile(displayName: displayName);
}

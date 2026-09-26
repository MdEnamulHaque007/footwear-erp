/// ============================================================================
/// ফাইল: lib/domain/usecases/user/reset_password_usecase.dart
/// স্তর: Domain Use Case | মডিউল: User Management
/// উদ্দেশ্য: User Management মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: ResetPasswordUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../repositories/i_auth_repository.dart';

class ResetPasswordUseCase {
  ResetPasswordUseCase(this._repository);
  final IAuthRepository _repository;
  Future<void> call(String email) => _repository.resetPassword(email);
}

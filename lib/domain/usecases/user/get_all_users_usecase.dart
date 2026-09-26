/// ============================================================================
/// ফাইল: lib/domain/usecases/user/get_all_users_usecase.dart
/// স্তর: Domain Use Case | মডিউল: User Management
/// উদ্দেশ্য: User Management মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GetAllUsersUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../entities/user_entity.dart';
import '../../repositories/i_user_repository.dart';

class GetAllUsersUseCase {
  GetAllUsersUseCase(this._repository);
  final IUserRepository _repository;
  Future<Either<String, List<UserEntity>>> call({int page = 0, int limit = 20}) => 
      _repository.getAllUsers(page: page, limit: limit);
}

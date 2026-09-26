/// ============================================================================
/// ফাইল: lib/domain/usecases/role/create_role_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Role Management
/// উদ্দেশ্য: Role Management মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: CreateRoleUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../entities/role_entity.dart';
import '../../repositories/i_role_repository.dart';

class CreateRoleUseCase {
  CreateRoleUseCase(this._repository);
  final IRoleRepository _repository;
  Future<Either<String, RoleEntity>> call(String name, Map<String, Map<String, bool>> permissions) => _repository.createRole(name, permissions);
}

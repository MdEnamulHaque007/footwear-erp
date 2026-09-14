import 'package:dartz/dartz.dart';
import '../../entities/user_entity.dart';
import '../../repositories/i_user_repository.dart';

/// Loads a single user profile by uid (detail / edit screens).
class GetUserByIdUseCase {
  GetUserByIdUseCase(this._repository);
  final IUserRepository _repository;
  Future<Either<String, UserEntity?>> call(String uid) => _repository.byId(uid);
}

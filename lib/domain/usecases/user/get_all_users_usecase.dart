import 'package:dartz/dartz.dart';
import '../../entities/user_entity.dart';
import '../../repositories/i_user_repository.dart';

class GetAllUsersUseCase {
  GetAllUsersUseCase(this._repository);
  final IUserRepository _repository;
  Future<Either<String, List<UserEntity>>> call({int page = 0, int limit = 20}) => 
      _repository.getAllUsers(page: page, limit: limit);
}

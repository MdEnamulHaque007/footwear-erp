import 'package:dartz/dartz.dart';
import '../../repositories/i_user_repository.dart';

class DeleteUserUseCase {
  DeleteUserUseCase(this._repository);
  final IUserRepository _repository;
  Future<Either<String, void>> call(String uid) => _repository.deleteUser(uid);
}

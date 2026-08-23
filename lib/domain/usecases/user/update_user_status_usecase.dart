import 'package:dartz/dartz.dart';
import '../../repositories/i_user_repository.dart';

class UpdateUserStatusUseCase {
  UpdateUserStatusUseCase(this._repository);
  final IUserRepository _repository;
  Future<Either<String, void>> call(String uid, bool isActive) => _repository.updateUserStatus(uid, isActive);
}

import '../../repositories/i_auth_repository.dart';

class ResetPasswordUseCase {
  ResetPasswordUseCase(this._repository);
  final IAuthRepository _repository;
  Future<void> call(String email) => _repository.resetPassword(email);
}

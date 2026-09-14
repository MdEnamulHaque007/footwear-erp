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

import 'package:dartz/dartz.dart';
import '../../entities/sewing_entity.dart';
import '../../repositories/i_sewing_repository.dart';

class UpdateSewingUseCase {
  UpdateSewingUseCase(this._repository);
  final ISewingRepository _repository;
  Future<Either<String, void>> call(SewingEntity item) =>
      _repository.update(item);
}

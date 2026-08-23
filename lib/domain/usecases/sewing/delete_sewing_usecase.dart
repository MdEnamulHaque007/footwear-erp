import 'package:dartz/dartz.dart';
import '../../repositories/i_sewing_repository.dart';

class DeleteSewingUseCase {
  DeleteSewingUseCase(this._repository);
  final ISewingRepository _repository;
  Future<Either<String, void>> call(String id) => _repository.delete(id);
}

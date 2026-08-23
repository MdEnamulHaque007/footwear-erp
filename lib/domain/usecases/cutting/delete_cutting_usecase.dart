import 'package:dartz/dartz.dart';
import '../../repositories/i_cutting_repository.dart';

class DeleteCuttingUseCase {
  DeleteCuttingUseCase(this._repository);
  final ICuttingRepository _repository;
  Future<Either<String, void>> call(String id) => _repository.delete(id);
}

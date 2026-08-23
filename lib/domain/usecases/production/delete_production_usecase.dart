import 'package:dartz/dartz.dart';
import '../../repositories/i_production_repository.dart';

class DeleteProductionUseCase {
  DeleteProductionUseCase(this._repository);
  final IProductionRepository _repository;
  Future<Either<String, void>> call(String id) => _repository.delete(id);
}

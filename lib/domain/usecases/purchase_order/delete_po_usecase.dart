import 'package:dartz/dartz.dart';
import '../../repositories/i_po_repository.dart';

class DeletePOUseCase {
  DeletePOUseCase(this._repository);
  final IPORepository _repository;
  Future<Either<String, void>> call(String id) => _repository.delete(id);
}

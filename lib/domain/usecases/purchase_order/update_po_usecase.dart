import 'package:dartz/dartz.dart';
import '../../entities/po_entity.dart';
import '../../repositories/i_po_repository.dart';

class UpdatePOUseCase {
  UpdatePOUseCase(this._repository);
  final IPORepository _repository;
  Future<Either<String, void>> call(POEntity item) => _repository.update(item);
}

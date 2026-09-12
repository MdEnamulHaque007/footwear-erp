import 'package:dartz/dartz.dart';
import '../../entities/po_entity.dart';
import '../../repositories/i_po_repository.dart';
import 'validate_po_quantity_usecase.dart';

class CreatePOUseCase {
  CreatePOUseCase(this._repository, [this._validate]);
  final IPORepository _repository;
  final ValidatePOQuantityUseCase? _validate;
  Future<Either<String, void>> call(POEntity item) async {
    final error = _validate == null
        ? null
        : await _validate.validateCandidate(item);
    if (error != null) return Left(error);
    return _repository.createPO(item);
  }
}

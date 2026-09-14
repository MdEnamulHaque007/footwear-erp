import 'package:dartz/dartz.dart';
import '../../entities/po_entity.dart';
import '../../repositories/i_po_repository.dart';
import 'validate_po_quantity_usecase.dart';

/// Updates a Purchase Order.
///
/// PO No uniqueness is re-checked with the edited record self-excluded, and the
/// Sl. is retained by the repository transaction.
class UpdatePOUseCase {
  UpdatePOUseCase(this._repository, [this._validate]);
  final IPORepository _repository;
  final ValidatePOQuantityUseCase? _validate;
  Future<Either<String, void>> call(POEntity item) async {
    if (item.poNo.trim().isEmpty) {
      return const Left('PO No is required');
    }
    final unique = await _repository.isPoNoUnique(
      item.poNo,
      excludeId: item.id,
    );
    if (!unique) {
      return Left('PO No ${item.poNo.trim()} already exists');
    }
    final error = _validate == null
        ? null
        : await _validate.validateCandidate(item);
    if (error != null) return Left(error);
    return _repository.updateWithTransaction(item);
  }
}

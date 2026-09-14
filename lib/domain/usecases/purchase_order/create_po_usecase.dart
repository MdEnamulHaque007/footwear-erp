import 'package:dartz/dartz.dart';
import '../../entities/po_entity.dart';
import '../../repositories/i_po_repository.dart';
import 'validate_po_quantity_usecase.dart';

/// Creates a Purchase Order.
///
/// SRS Rule 1: the Sl. is auto-generated, so any caller-supplied value is
/// discarded and the repository allocates the next sequence number atomically.
/// PO No is globally unique — checked here for a friendly message and again
/// inside the repository transaction.
class CreatePOUseCase {
  CreatePOUseCase(this._repository, [this._validate]);
  final IPORepository _repository;
  final ValidatePOQuantityUseCase? _validate;
  Future<Either<String, void>> call(POEntity item) async {
    if (item.poNo.trim().isEmpty) {
      return const Left('PO No is required');
    }
    final unique = await _repository.isPoNoUnique(item.poNo);
    if (!unique) {
      return Left('PO No ${item.poNo.trim()} already exists');
    }
    final error = _validate == null
        ? null
        : await _validate.validateCandidate(item);
    if (error != null) return Left(error);
    // Sl. is assigned by the repository inside the create transaction.
    return _repository.createWithTransaction(item.copyWith(sl: 0));
  }
}

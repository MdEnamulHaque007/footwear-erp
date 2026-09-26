import 'package:dartz/dartz.dart';
import '../../entities/sewing_entity.dart';
import '../../repositories/i_sewing_repository.dart';
import 'validate_sewing_quantity_usecase.dart';

/// Updates a Sewing entry.
///
/// Uses [ISewingRepository.updateWithTransaction] so the edited document is
/// self-excluded from the cumulative Sewing total inside the same atomic
/// read/validate/write cycle.
class UpdateSewingUseCase {
  UpdateSewingUseCase(this._repository, this._validate);
  final ISewingRepository _repository;
  final ValidateSewingQuantityUseCase _validate;

  Future<Either<String, void>> call(SewingEntity item) async {
    if (item.poNo.isNotEmpty) {
      final error = await _validate.validateUpdate(
        sewingId: item.id ?? '',
        poNo: item.poNo,
        article: item.article,
        color: item.color,
        candidateQuantity: item.sewingQuantity,
        sewingDate: item.sewingDate,
      );
      if (error != null) return Left(error);
      return _repository.updateWithTransaction(item);
    }
    return _repository.update(item);
  }
}

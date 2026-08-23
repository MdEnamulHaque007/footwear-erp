import 'package:dartz/dartz.dart';
import '../../entities/sewing_entity.dart';
import '../../repositories/i_sewing_repository.dart';
import 'validate_sewing_quantity_usecase.dart';

class CreateSewingUseCase {
  CreateSewingUseCase(this._repository, this._validate);
  final ISewingRepository _repository;
  final ValidateSewingQuantityUseCase _validate;

  Future<Either<String, void>> call(SewingEntity item) async {
    final error = await _validate(
      poTagNo: item.poTagNo,
      sewingDate: item.sewingDate,
      candidateQuantity: item.quantity,
    );
    if (error != null) return Left(error);
    return _repository.createSewing(item);
  }
}

import 'package:dartz/dartz.dart';
import '../../entities/export_entity.dart';
import '../../repositories/i_export_repository.dart';
import 'validate_export_quantity_usecase.dart';

/// Updates an Export entry, self-excluding the edited document from the
/// cumulative Export total inside the same atomic read/validate/write cycle.
class UpdateExportUseCase {
  UpdateExportUseCase(this._repository, this._validate);
  final IExportRepository _repository;
  final ValidateExportQuantityUseCase _validate;

  Future<Either<String, void>> call(ExportEntity item) async {
    if (item.poNo.isNotEmpty) {
      final error = await _validate.validateUpdate(
        exportId: item.id ?? '',
        poNo: item.poNo,
        article: item.article,
        color: item.color,
        candidateQuantity: item.quantity,
        exportDate: item.exportDate,
      );
      if (error != null) return Left(error);
      return _repository.updateWithTransaction(item);
    }
    return _repository.update(item);
  }
}

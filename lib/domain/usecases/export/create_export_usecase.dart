import 'package:dartz/dartz.dart';
import '../../entities/export_entity.dart';
import '../../repositories/i_export_repository.dart';
import 'validate_export_quantity_usecase.dart';

/// Creates an Export entry.
///
/// PO-driven entries are written through
/// [IExportRepository.createWithTransaction] so the cumulative Issue / Export
/// check and the write are atomic, which keeps two concurrent devices from
/// over-consuming the same Issue quantity.
class CreateExportUseCase {
  CreateExportUseCase(this._repository, this._validate);
  final IExportRepository _repository;
  final ValidateExportQuantityUseCase _validate;

  Future<Either<String, void>> call(ExportEntity item) async {
    if (item.poNo.isNotEmpty) {
      final error = await _validate(
        poNo: item.poNo,
        article: item.article,
        color: item.color,
        candidateQuantity: item.quantity,
        exportDate: item.exportDate,
      );
      if (error != null) return Left(error);
      return _repository.createWithTransaction(item);
    }
    return _repository.createExport(item);
  }
}

import 'package:dartz/dartz.dart';
import '../../entities/cutting_entity.dart';
import '../../repositories/i_cutting_repository.dart';

/// Distinct Article + Color pairs recorded in the PO line items of a PO.
///
/// Drives the Cutting form's cascading dropdowns.
class GetCuttingPOLinesUseCase {
  GetCuttingPOLinesUseCase(this._repository);
  final ICuttingRepository _repository;
  Future<Either<String, List<CuttingLine>>> call(String poNo) =>
      _repository.getPOLines(poNo);
}

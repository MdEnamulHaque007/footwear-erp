import 'package:dartz/dartz.dart';
import '../../repositories/i_production_repository.dart';

/// PO No list for the Production form's PO dropdown.
///
/// Sourced from the Sewing entries, so only POs that have actually been sewn can
/// be produced.
class GetProductionPOListUseCase {
  GetProductionPOListUseCase(this._repository);
  final IProductionRepository _repository;

  Future<Either<String, List<String>>> call() =>
      _repository.getSewingEntryPONoList();
}

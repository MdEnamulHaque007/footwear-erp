import 'package:dartz/dartz.dart';
import '../../entities/production_entity.dart';
import '../../repositories/i_production_repository.dart';

/// Distinct Article + Color pairs recorded in the Sewing entries of a PO.
///
/// Drives the Production form's cascading dropdowns: a line can only be
/// produced once it has been sewn.
class GetArticleColorsUseCase {
  GetArticleColorsUseCase(this._repository);
  final IProductionRepository _repository;

  Future<Either<String, List<SewingLine>>> call(String poNo) =>
      _repository.getSewingEntryLines(poNo);
}

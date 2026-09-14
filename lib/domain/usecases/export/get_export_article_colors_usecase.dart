import 'package:dartz/dartz.dart';
import '../../entities/export_entity.dart';
import '../../repositories/i_export_repository.dart';

/// Distinct Article + Color pairs recorded in the Issue entries of a PO.
///
/// Drives the Export form's cascading dropdowns: a line can only be exported
/// once it has been issued.
class GetExportArticleColorsUseCase {
  GetExportArticleColorsUseCase(this._repository);
  final IExportRepository _repository;

  Future<Either<String, List<IssueLine>>> call(String poNo) =>
      _repository.getIssueEntryLines(poNo);
}

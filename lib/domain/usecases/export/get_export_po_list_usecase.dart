import 'package:dartz/dartz.dart';
import '../../repositories/i_export_repository.dart';

/// PO No list for the Export form's PO dropdown.
///
/// Sourced from the Issue entries, so only POs that have actually been issued
/// can be exported.
class GetExportPOListUseCase {
  GetExportPOListUseCase(this._repository);
  final IExportRepository _repository;

  Future<Either<String, List<String>>> call() =>
      _repository.getIssueEntryPONoList();
}

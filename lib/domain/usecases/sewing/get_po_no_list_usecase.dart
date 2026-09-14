import 'package:dartz/dartz.dart';
import '../../repositories/i_sewing_repository.dart';

/// PO No list for the Sewing form's PO dropdown.
///
/// Sourced from the Cutting entries (chain enforcement): a PO only becomes
/// selectable for Sewing once something has actually been cut for it.
class GetSewingPONoListUseCase {
  GetSewingPONoListUseCase(this._repository);
  final ISewingRepository _repository;

  Future<Either<String, List<String>>> call() =>
      _repository.getCuttingEntryPONoList();
}

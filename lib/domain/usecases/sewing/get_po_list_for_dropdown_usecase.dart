import 'package:dartz/dartz.dart';
import '../../../data/models/purchase_order/po_model.dart';
import '../../repositories/i_sewing_repository.dart';

/// Full PO documents for the Sewing form's PO dropdown (PO No + Tag/Company).
class GetSewingPOListForDropdownUseCase {
  GetSewingPOListForDropdownUseCase(this._repository);
  final ISewingRepository _repository;
  Future<Either<String, List<POModel>>> call() =>
      _repository.getPOListForDropdown();
}


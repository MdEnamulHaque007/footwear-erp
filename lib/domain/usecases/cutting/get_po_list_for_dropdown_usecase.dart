import 'package:dartz/dartz.dart';
import '../../../data/models/purchase_order/po_model.dart';
import '../../repositories/i_cutting_repository.dart';

class GetPOListForDropdownUseCase {
  GetPOListForDropdownUseCase(this._repository);
  final ICuttingRepository _repository;
  Future<Either<String, List<POModel>>> call() =>
      _repository.getPOListForDropdown();
}

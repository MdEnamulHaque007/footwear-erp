import 'package:dartz/dartz.dart';
import '../../repositories/i_po_repository.dart';
import '../../../data/models/purchase_order/po_model.dart';

/// Loads a single Purchase Order by document id (detail / edit screens).
class GetPOByIdUseCase {
  GetPOByIdUseCase(this._repository);
  final IPORepository _repository;

  Future<Either<String, POModel?>> call(String id) => _repository.byId(id);
}

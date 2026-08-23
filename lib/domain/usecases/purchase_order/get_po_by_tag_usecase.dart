import 'package:dartz/dartz.dart';
import '../../repositories/i_po_repository.dart';
import '../../../data/models/purchase_order/po_model.dart';

class GetPOByTagUseCase {
  GetPOByTagUseCase(this._repository);
  final IPORepository _repository;
  Future<Either<String, List<POModel>>> call(String tag) => _repository.byTag(tag);
}

import 'package:dartz/dartz.dart';
import '../../repositories/i_po_repository.dart';
import '../../../data/models/purchase_order/po_model.dart';

class GetPOListUseCase {
  GetPOListUseCase(this._repository);
  final IPORepository _repository;
  Future<Either<String, List<POModel>>> call({int page = 0, int limit = 20}) =>
      _repository.getPOList(page: page, limit: limit);
}

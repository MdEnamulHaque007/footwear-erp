import 'package:dartz/dartz.dart';
import '../../../data/models/purchase_order/po_model.dart';
import '../../repositories/i_cutting_repository.dart';

class GetPOByNoUseCase {
  GetPOByNoUseCase(this._repository);
  final ICuttingRepository _repository;
  Future<Either<String, POModel?>> call(String poNo) =>
      _repository.getPOByNo(poNo);
}

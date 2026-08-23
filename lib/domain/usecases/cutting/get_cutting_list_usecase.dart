import 'package:dartz/dartz.dart';
import '../../../data/models/cutting/cutting_model.dart';
import '../../repositories/i_cutting_repository.dart';

class GetCuttingListUseCase {
  GetCuttingListUseCase(this._repository);
  final ICuttingRepository _repository;
  Future<Either<String, List<CuttingModel>>> call({
    int page = 0,
    int limit = 20,
  }) => _repository.getCuttingList(page: page, limit: limit);
}

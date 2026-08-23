import 'package:dartz/dartz.dart';
import '../../../data/models/sewing/sewing_model.dart';
import '../../repositories/i_sewing_repository.dart';

class GetSewingListUseCase {
  GetSewingListUseCase(this._repository);
  final ISewingRepository _repository;
  Future<Either<String, List<SewingModel>>> call({
    int page = 0,
    int limit = 20,
  }) => _repository.getSewingList(page: page, limit: limit);
}

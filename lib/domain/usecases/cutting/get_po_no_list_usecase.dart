import 'package:dartz/dartz.dart';
import '../../repositories/i_cutting_repository.dart';

class GetPONoListUseCase {
  GetPONoListUseCase(this._repository);
  final ICuttingRepository _repository;
  Future<Either<String, List<String>>> call() => _repository.getPONoList();
}

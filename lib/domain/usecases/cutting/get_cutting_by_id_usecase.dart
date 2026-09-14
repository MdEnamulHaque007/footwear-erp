import 'package:dartz/dartz.dart';
import '../../repositories/i_cutting_repository.dart';
import '../../../data/models/cutting/cutting_model.dart';

/// Loads a single Cutting record by document id (detail / edit screens).
class GetCuttingByIdUseCase {
  GetCuttingByIdUseCase(this._repository);
  final ICuttingRepository _repository;
  Future<Either<String, CuttingModel?>> call(String id) => _repository.byId(id);
}

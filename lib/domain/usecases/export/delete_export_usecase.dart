import 'package:dartz/dartz.dart';
import '../../repositories/i_export_repository.dart';

class DeleteExportUseCase {
  DeleteExportUseCase(this._repository);
  final IExportRepository _repository;
  Future<Either<String, void>> call(String id) => _repository.delete(id);
}

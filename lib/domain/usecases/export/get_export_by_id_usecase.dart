import 'package:dartz/dartz.dart';
import '../../repositories/i_export_repository.dart';
import '../../../data/models/export/export_model.dart';

/// Loads a single Export record by document id (detail / edit screens).
class GetExportByIdUseCase {
  GetExportByIdUseCase(this._repository);
  final IExportRepository _repository;

  Future<Either<String, ExportModel?>> call(String id) => _repository.byId(id);
}

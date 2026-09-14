import 'package:dartz/dartz.dart';
import '../../repositories/i_export_repository.dart';
import '../../../data/models/export/export_model.dart';

class GetExportListUseCase {
  GetExportListUseCase(this._repository);
  final IExportRepository _repository;
  Future<Either<String, List<ExportModel>>> call({
    int page = 0,
    int limit = 20,
  }) => _repository.getExportList(page: page, limit: limit);
}

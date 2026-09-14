import 'package:dartz/dartz.dart';
import '../../entities/dashboard/dashboard_chart_data_entity.dart';
import '../../repositories/i_dashboard_repository.dart';

class GetProductionTrendUseCase {
  GetProductionTrendUseCase(this._repository);
  final IDashboardRepository _repository;

  Future<Either<String, List<MultiSeriesDataPoint>>> call(int days) =>
      _repository.getProductionTrend(days);
}

import 'package:dartz/dartz.dart';
import '../../entities/dashboard/dashboard_chart_data_entity.dart';
import '../../repositories/i_dashboard_repository.dart';

class GetFactoryComparisonUseCase {
  GetFactoryComparisonUseCase(this._repository);
  final IDashboardRepository _repository;

  Future<Either<String, List<ChartDataPoint>>> call() =>
      _repository.getFactoryComparison();
}

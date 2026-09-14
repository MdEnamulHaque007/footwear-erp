import 'package:dartz/dartz.dart';
import '../../entities/dashboard/dashboard_stats_entity.dart';
import '../../repositories/i_dashboard_repository.dart';

class GetDashboardStatsUseCase {
  GetDashboardStatsUseCase(this._repository);
  final IDashboardRepository _repository;

  Future<Either<String, DashboardStatsEntity>> call() =>
      _repository.getStats();
}

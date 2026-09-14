import 'package:dartz/dartz.dart';
import '../../entities/dashboard/dashboard_quick_stats_entity.dart';
import '../../repositories/i_dashboard_repository.dart';

class GetQuickStatsUseCase {
  GetQuickStatsUseCase(this._repository);
  final IDashboardRepository _repository;

  Future<Either<String, DashboardQuickStatsEntity>> call() =>
      _repository.getQuickStats();
}

import 'package:dartz/dartz.dart';
import '../../entities/dashboard/dashboard_activity_entity.dart';
import '../../repositories/i_dashboard_repository.dart';

class GetRecentActivitiesUseCase {
  GetRecentActivitiesUseCase(this._repository);
  final IDashboardRepository _repository;

  Future<Either<String, List<DashboardActivityEntity>>> call(int limit) =>
      _repository.getRecentActivities(limit);
}

import 'package:dartz/dartz.dart';

import '../../entities/dashboard/comparison_matrix_entity.dart';
import '../../entities/dashboard/criteria_option_entity.dart';
import '../../repositories/i_dashboard_repository.dart';

class GetComparisonMatrixUseCase {
  GetComparisonMatrixUseCase(this._repository);

  final IDashboardRepository _repository;

  Future<Either<String, ComparisonMatrix>> call({
    required List<String> collections,
    required List<String> dateFields,
    required CriteriaOption xCriteria,
    required CriteriaOption yCriteria,
    required ValueType valueType,
    required DateTime fromDate,
    required DateTime toDate,
  }) => _repository.getComparisonMatrix(
    collections: collections,
    dateFields: dateFields,
    xCriteria: xCriteria,
    yCriteria: yCriteria,
    valueType: valueType,
    fromDate: fromDate,
    toDate: toDate,
  );
}

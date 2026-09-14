import 'package:dartz/dartz.dart';
import '../../entities/dashboard/comparison_data_entity.dart';
import '../../repositories/i_dashboard_repository.dart';

/// Fetches one side of the department comparison.
///
/// The collection and field names come from the caller's `DepartmentOption`, so
/// any two stages of the production chain can be compared over independent date
/// ranges.
class GetComparisonDataUseCase {
  GetComparisonDataUseCase(this._repository);
  final IDashboardRepository _repository;

  Future<Either<String, ComparisonRangeEntity>> call({
    required String collection,
    required String dateField,
    required String quantityField,
    required DateTime fromDate,
    required DateTime toDate,
    required String label,
    required String department,
  }) => _repository.getComparisonData(
    collection: collection,
    dateField: dateField,
    quantityField: quantityField,
    fromDate: fromDate,
    toDate: toDate,
    label: label,
    department: department,
  );
}


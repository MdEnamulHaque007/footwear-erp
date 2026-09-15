import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/domain/entities/dashboard/comparison_matrix_entity.dart';
import 'package:footwear/domain/entities/dashboard/criteria_option_entity.dart';

void main() {
  final date = DateTime(2026, 1, 1);
  final matrix = ComparisonMatrix(
    xCriteria: CriteriaOption.all.first,
    yCriteria: CriteriaOption.all[1],
    valueType: ValueType.quantity,
    fromDate: date,
    toDate: date,
    xLabels: const ['Jan', 'Feb'],
    yLabels: const ['Cutting', 'Sewing'],
    data: const [
      [10, 20],
      [5, 30],
    ],
  );

  group('CriteriaOption', () {
    test('provides ten unique criteria fields', () {
      expect(CriteriaOption.all, hasLength(10));
      expect(CriteriaOption.all.map((option) => option.field).toSet(), hasLength(10));
    });

    test('every criteria has a display icon', () {
      expect(CriteriaOption.all.every((option) => option.icon.isNotEmpty), isTrue);
    });

    test('includes all criteria types', () {
      expect(CriteriaOption.all.map((option) => option.type), containsAll(CriteriaType.values));
    });

    test('finds a criteria by field', () {
      expect(CriteriaOption.fromField('factoryName').label, 'Factory');
    });

    test('falls back to date for an unknown field', () {
      expect(CriteriaOption.fromField('missing').field, 'date');
    });
  });

  group('ValueType', () {
    test('has quantity and value options', () {
      expect(ValueType.values, [ValueType.quantity, ValueType.value]);
    });

    test('both options have labels', () {
      expect(ValueType.values.every((value) => value.label.isNotEmpty), isTrue);
    });
  });

  group('ComparisonMatrix', () {
    test('returns a valid matrix position', () {
      expect(matrix.valueAt(1, 0), 20);
    });

    test('returns zero outside its bounds', () {
      expect(matrix.valueAt(-1, 0), 0);
      expect(matrix.valueAt(0, -1), 0);
      expect(matrix.valueAt(3, 0), 0);
      expect(matrix.valueAt(0, 3), 0);
    });

    test('calculates the largest value', () {
      expect(matrix.maxValue, 30);
    });

    test('is not empty when all dimensions have data', () {
      expect(matrix.isEmpty, isFalse);
    });

    test('is empty without labels', () {
      final empty = ComparisonMatrix(
        xCriteria: CriteriaOption.all.first,
        yCriteria: CriteriaOption.all[1],
        valueType: ValueType.quantity,
        fromDate: date,
        toDate: date,
        xLabels: const [],
        yLabels: const [],
        data: const [],
      );
      expect(empty.isEmpty, isTrue);
    });

    test('is empty without matrix rows', () {
      final empty = ComparisonMatrix(
        xCriteria: CriteriaOption.all.first,
        yCriteria: CriteriaOption.all[1],
        valueType: ValueType.value,
        fromDate: date,
        toDate: date,
        xLabels: const ['Jan'],
        yLabels: const ['Cutting'],
        data: const [],
      );
      expect(empty.isEmpty, isTrue);
    });
  });
}

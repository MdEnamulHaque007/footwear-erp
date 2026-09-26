/// ============================================================================
/// ফাইল: lib/domain/entities/dashboard/comparison_matrix_entity.dart
/// স্তর: Domain Entity | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের framework-independent business data ও হিসাবযোগ্য property সংজ্ঞায়িত করে।
/// প্রধান অংশ: ComparisonMatrix
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'criteria_option_entity.dart';

class ComparisonMatrix {
  const ComparisonMatrix({
    required this.xCriteria,
    required this.yCriteria,
    required this.valueType,
    required this.fromDate,
    required this.toDate,
    required this.xLabels,
    required this.yLabels,
    required this.data,
  });

  final CriteriaOption xCriteria;
  final CriteriaOption yCriteria;
  final ValueType valueType;
  final DateTime fromDate;
  final DateTime toDate;
  final List<String> xLabels;
  final List<String> yLabels;

  /// Rows are Y labels, columns are X labels.
  final List<List<double>> data;

  double valueAt(int xIndex, int yIndex) {
    if (yIndex < 0 || yIndex >= data.length) return 0;
    final row = data[yIndex];
    if (xIndex < 0 || xIndex >= row.length) return 0;
    return row[xIndex];
  }

  double get maxValue {
    var max = 0.0;
    for (final row in data) {
      for (final value in row) {
        if (value > max) max = value;
      }
    }
    return max;
  }

  bool get isEmpty => xLabels.isEmpty || yLabels.isEmpty || data.isEmpty;
}

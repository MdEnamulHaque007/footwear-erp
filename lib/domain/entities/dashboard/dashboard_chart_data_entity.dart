/// ============================================================================
/// ফাইল: lib/domain/entities/dashboard/dashboard_chart_data_entity.dart
/// স্তর: Domain Entity | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের framework-independent business data ও হিসাবযোগ্য property সংজ্ঞায়িত করে।
/// প্রধান অংশ: ChartDataPoint, MultiSeriesDataPoint
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:equatable/equatable.dart';

/// One labelled value, used by the pie and bar charts.
class ChartDataPoint extends Equatable {
  const ChartDataPoint({required this.label, required this.value});

  final String label;
  final double value;

  @override
  List<Object?> get props => [label, value];
}

/// One labelled point holding several named series, used by the multi-series
/// line chart (e.g. label = `12 Sep`, series = {Cutting: 40, Sewing: 35, ...}).
class MultiSeriesDataPoint extends Equatable {
  const MultiSeriesDataPoint({required this.label, required this.series});

  final String label;
  final Map<String, double> series;

  /// Value for [key], or `0` when the series has no entry for this point.
  double valueOf(String key) => series[key] ?? 0;

  @override
  List<Object?> get props => [label, series];
}

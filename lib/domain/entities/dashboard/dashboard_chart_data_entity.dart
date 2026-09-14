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

import 'package:equatable/equatable.dart';

/// Rolling totals for today, the current week and the current month.
class DashboardQuickStatsEntity extends Equatable {
  const DashboardQuickStatsEntity({
    this.todayQuantity = 0,
    this.todayValue = 0,
    this.weekQuantity = 0,
    this.weekValue = 0,
    this.monthQuantity = 0,
    this.monthValue = 0,
  });

  factory DashboardQuickStatsEntity.defaults() =>
      const DashboardQuickStatsEntity();

  final int todayQuantity;
  final double todayValue;
  final int weekQuantity;
  final double weekValue;
  final int monthQuantity;
  final double monthValue;

  /// Percentage change of the week total against the month total, used for the
  /// trend arrow. Returns `0` when the month has no value yet.
  double get weekTrend =>
      monthValue == 0 ? 0 : (weekValue / monthValue) * 100;

  DashboardQuickStatsEntity copyWith({
    int? todayQuantity,
    double? todayValue,
    int? weekQuantity,
    double? weekValue,
    int? monthQuantity,
    double? monthValue,
  }) => DashboardQuickStatsEntity(
    todayQuantity: todayQuantity ?? this.todayQuantity,
    todayValue: todayValue ?? this.todayValue,
    weekQuantity: weekQuantity ?? this.weekQuantity,
    weekValue: weekValue ?? this.weekValue,
    monthQuantity: monthQuantity ?? this.monthQuantity,
    monthValue: monthValue ?? this.monthValue,
  );

  @override
  List<Object?> get props => [
    todayQuantity,
    todayValue,
    weekQuantity,
    weekValue,
    monthQuantity,
    monthValue,
  ];
}

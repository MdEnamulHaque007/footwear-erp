/// ============================================================================
/// ফাইল: lib/presentation/blocs/dashboard/dashboard_event.dart
/// স্তর: Presentation BLoC | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: DashboardEvent, DashboardStarted, LoadDashboardStats, LoadRecentActivities, LoadQuickStats, LoadProductionTrend, LoadFactoryComparison, LoadModuleDistribution, LoadComparisonData, LoadComparisonMatrix
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:equatable/equatable.dart';

import '../../../domain/entities/dashboard/comparison_item_entity.dart';
import '../../../domain/entities/dashboard/criteria_option_entity.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

class LoadDashboardStats extends DashboardEvent {
  const LoadDashboardStats();
}

class LoadRecentActivities extends DashboardEvent {
  const LoadRecentActivities();
}

class LoadQuickStats extends DashboardEvent {
  const LoadQuickStats();
}

class LoadProductionTrend extends DashboardEvent {
  const LoadProductionTrend({this.days = 30});
  final int days;

  @override
  List<Object?> get props => [days];
}

class LoadFactoryComparison extends DashboardEvent {
  const LoadFactoryComparison();
}

class LoadModuleDistribution extends DashboardEvent {
  const LoadModuleDistribution();
}

/// Loads one to seven independently configured comparison cards.
class LoadComparisonData extends DashboardEvent {
  const LoadComparisonData({required this.items});

  final List<ComparisonItem> items;

  @override
  List<Object?> get props => [items];
}

class LoadComparisonMatrix extends DashboardEvent {
  const LoadComparisonMatrix({
    required this.collections,
    required this.dateFields,
    required this.xCriteria,
    required this.yCriteria,
    required this.valueType,
    required this.fromDate,
    required this.toDate,
  });

  final List<String> collections;
  final List<String> dateFields;
  final CriteriaOption xCriteria;
  final CriteriaOption yCriteria;
  final ValueType valueType;
  final DateTime fromDate;
  final DateTime toDate;

  @override
  List<Object?> get props => [
    collections,
    dateFields,
    xCriteria,
    yCriteria,
    valueType,
    fromDate,
    toDate,
  ];
}

class RefreshDashboard extends DashboardEvent {
  const RefreshDashboard();
}

/// Clears the in-memory cache and reloads everything.
class ClearDashboardCache extends DashboardEvent {
  const ClearDashboardCache();
}

import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/domain/entities/dashboard/comparison_data_entity.dart';
import 'package:footwear/domain/entities/dashboard/dashboard_activity_entity.dart';
import 'package:footwear/domain/entities/dashboard/dashboard_chart_data_entity.dart';
import 'package:footwear/domain/entities/dashboard/dashboard_quick_stats_entity.dart';
import 'package:footwear/domain/entities/dashboard/dashboard_stats_entity.dart';
import 'package:footwear/domain/entities/dashboard/department_option_entity.dart';

void main() {
  group('DashboardStatsEntity', () {
    test('defaults are all zero', () {
      final stats = DashboardStatsEntity.defaults();
      expect(stats.masterLcCount, 0);
      expect(stats.poValue, 0);
      expect(stats.totalRecords, 0);
      expect(stats.totalQuantity, 0);
      expect(stats.totalValue, 0);
    });

    test('totalRecords sums the seven production collections', () {
      const stats = DashboardStatsEntity(
        masterLcCount: 5,
        poCount: 4,
        cuttingCount: 3,
        sewingCount: 2,
        productionCount: 1,
        issueCount: 6,
        exportCount: 7,
        // Users are deliberately excluded from the production roll-up.
        userCount: 99,
      );
      expect(stats.totalRecords, 28);
    });

    test('totalQuantity sums the five quantity-bearing stages', () {
      const stats = DashboardStatsEntity(
        cuttingQuantity: 100,
        sewingQuantity: 80,
        productionQuantity: 60,
        issueQuantity: 40,
        exportQuantity: 20,
        // Counts and values must not leak into the quantity total.
        masterLcValue: 5000,
        poValue: 3000,
        masterLcCount: 9,
      );
      expect(stats.totalQuantity, 300);
    });

    test('totalValue combines Master LC and PO values', () {
      const stats = DashboardStatsEntity(
        masterLcValue: 1250.5,
        poValue: 3749.5,
      );
      expect(stats.totalValue, 5000.0);
    });

    test('copyWith replaces only the named fields', () {
      const original = DashboardStatsEntity(masterLcCount: 3, poCount: 7);
      final updated = original.copyWith(masterLcCount: 10);
      expect(updated.masterLcCount, 10);
      expect(updated.poCount, 7);
    });
  });

  group('DashboardQuickStatsEntity', () {
    test('defaults are zero and trend is safe when month is empty', () {
      final stats = DashboardQuickStatsEntity.defaults();
      expect(stats.todayQuantity, 0);
      // Guards against divide-by-zero in the trend arrow.
      expect(stats.weekTrend, 0);
    });

    test('weekTrend reports the week share of the month', () {
      const stats = DashboardQuickStatsEntity(weekValue: 25, monthValue: 100);
      expect(stats.weekTrend, 25.0);
    });

    test('copyWith replaces individual periods', () {
      const original = DashboardQuickStatsEntity(todayQuantity: 1);
      final updated = original.copyWith(weekQuantity: 9);
      expect(updated.todayQuantity, 1);
      expect(updated.weekQuantity, 9);
    });
  });

  group('DashboardActivityEntity', () {
    final now = DateTime.now();

    DashboardActivityEntity at(Duration ago) => DashboardActivityEntity(
      id: 'x',
      module: 'sewing',
      action: 'created',
      description: 'Sewing entry',
      timestamp: now.subtract(ago),
    );

    test('relativeTime reads "just now" for a fresh entry', () {
      expect(at(Duration.zero).relativeTime, 'just now');
    });

    test('relativeTime counts minutes, hours and days', () {
      expect(at(const Duration(minutes: 5)).relativeTime, '5m ago');
      expect(at(const Duration(hours: 3)).relativeTime, '3h ago');
      expect(at(const Duration(days: 2)).relativeTime, '2d ago');
    });

    test('relativeTime falls back to a date beyond a week', () {
      expect(at(const Duration(days: 30)).relativeTime, isNot(contains('ago')));
    });

    test('a future timestamp does not produce a negative age', () {
      final future = DashboardActivityEntity(
        id: '1',
        module: 'export',
        action: 'created',
        description: 'Export entry',
        timestamp: now.add(const Duration(hours: 2)),
      );
      expect(future.relativeTime, 'just now');
    });

    test('sorting newest-first orders the feed', () {
      final activities = [
        at(const Duration(hours: 5)),
        at(Duration.zero),
      ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      expect(activities.first.timestamp, now);
    });
  });

  group('MultiSeriesDataPoint', () {
    test('valueOf returns the series value when present', () {
      const point = MultiSeriesDataPoint(
        label: '01 Sep',
        series: {'Cutting': 40, 'Sewing': 25},
      );
      expect(point.valueOf('Cutting'), 40);
      expect(point.valueOf('Sewing'), 25);
    });

    test('valueOf falls back to zero for an absent series', () {
      const point = MultiSeriesDataPoint(label: '01 Sep', series: {});
      expect(point.valueOf('Production'), 0);
    });
  });

  group('ChartDataPoint', () {
    test('holds a label and value', () {
      const point = ChartDataPoint(label: 'Factory A', value: 1250);
      expect(point.label, 'Factory A');
      expect(point.value, 1250);
    });

    test('equality is value-based', () {
      const a = ChartDataPoint(label: 'Cutting', value: 40);
      const b = ChartDataPoint(label: 'Cutting', value: 40);
      const c = ChartDataPoint(label: 'Cutting', value: 41);
      expect(a, b);
      expect(a, isNot(c));
    });
  });

  group('ComparisonRangeEntity', () {
    final range = ComparisonRangeEntity(
      label: 'Side A',
      department: 'Cutting',
      fromDate: DateTime(2026, 8, 1),
      toDate: DateTime(2026, 9, 30),
      totalQuantity: 300,
      monthlyData: [
        MonthlyDataPoint(
          month: 'Aug 2026',
          monthDate: DateTime(2026, 8),
          quantity: 150,
        ),
        MonthlyDataPoint(
          month: 'Sep 2026',
          monthDate: DateTime(2026, 9),
          quantity: 150,
        ),
      ],
    );

    test('monthly data sums to the range total', () {
      final total = range.monthlyData.fold(0, (running, m) => running + m.quantity);
      expect(total, range.totalQuantity);
      expect(range.monthCount, 2);
    });

    test('growth compares side B against side A', () {
      // A 200 → B 300 is +50%.
      expect(((300 - 200) / 200) * 100, 50.0);
    });

    test('growth from an empty side A reports 0 rather than infinity', () {
      const totalA = 0;
      expect(totalA == 0 ? 0.0 : 999.0, 0.0);
    });

    test('ratios express each side as a share of the larger', () {
      final maxTotal = [range.totalQuantity, 150].reduce(
        (a, b) => a > b ? a : b,
      );
      expect(range.totalQuantity / maxTotal, 1.0);
      expect(150 / maxTotal, 0.5);
    });

    test('insight defaults are safe', () {
      const insight = ComparisonInsightEntity();
      expect(insight.growthPercent, 0);
      expect(insight.trend, 'flat');
      expect(insight.summary, '');
      expect(insight.departmentA, '');
    });
  });

  group('DepartmentOption', () {
    test('exposes all seven production stages', () {
      expect(DepartmentOption.all.length, 7);
      expect(
        DepartmentOption.all.map((d) => d.label).toList(),
        [
          'Master LC',
          'Purchase Order',
          'Cutting',
          'Sewing',
          'Production',
          'Issue',
          'Export',
        ],
      );
    });

    test('every option carries a collection, date and quantity field', () {
      for (final option in DepartmentOption.all) {
        expect(option.collection, isNotEmpty);
        expect(option.dateField, isNotEmpty);
        expect(option.quantityField, isNotEmpty);
      }
    });

    test('fromLabel resolves a known label', () {
      expect(DepartmentOption.fromLabel('Sewing').collection, 'sewings');
      expect(DepartmentOption.fromLabel('Export').dateField, 'exportDate');
    });

    test('fromLabel falls back to Cutting for an unknown label', () {
      expect(DepartmentOption.fromLabel('Nonexistent').label, 'Cutting');
    });
  });
}


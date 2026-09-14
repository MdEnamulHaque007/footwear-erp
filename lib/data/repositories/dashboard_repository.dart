import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/dashboard/comparison_data_entity.dart';
import '../../domain/entities/dashboard/dashboard_activity_entity.dart';
import '../../domain/entities/dashboard/dashboard_chart_data_entity.dart';
import '../../domain/entities/dashboard/dashboard_quick_stats_entity.dart';
import '../../domain/entities/dashboard/dashboard_stats_entity.dart';
import '../../domain/repositories/i_dashboard_repository.dart';

/// Firestore-backed dashboard aggregates.
///
/// Every stage collection is read in parallel with a hard [queryLimit] ceiling,
/// and all numeric fields are coerced defensively because older records and
/// Google Sheets imports may carry numbers as strings.
class DashboardRepository implements IDashboardRepository {
  DashboardRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Upper bound per collection read. The dashboard is an aggregate view, so a
  /// capped sample is preferred over an unbounded scan.
  static const int queryLimit = 1000;

  /// Series names and order used by the trend chart.
  static const List<String> _trendSeries = [
    'Cutting',
    'Sewing',
    'Production',
    'Issue',
    'Export',
  ];

  CollectionReference<Map<String, dynamic>> get _masterLc =>
      _db.collection(AppConstants.collectionMasterLC);
  CollectionReference<Map<String, dynamic>> get _po =>
      _db.collection(AppConstants.collectionPO);
  CollectionReference<Map<String, dynamic>> get _cutting =>
      _db.collection(AppConstants.collectionCutting);
  CollectionReference<Map<String, dynamic>> get _sewing =>
      _db.collection(AppConstants.collectionSewing);
  CollectionReference<Map<String, dynamic>> get _production =>
      _db.collection(AppConstants.collectionProduction);
  CollectionReference<Map<String, dynamic>> get _issue =>
      _db.collection(AppConstants.collectionIssue);
  CollectionReference<Map<String, dynamic>> get _export =>
      _db.collection(AppConstants.collectionExport);
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(AppConstants.collectionUsers);

  // ---------------------------------------------------------------- stats

  @override
  Future<Either<String, DashboardStatsEntity>> getStats() async {
    try {
      final results = await Future.wait([
        _masterLc.limit(queryLimit).get(),
        _po.limit(queryLimit).get(),
        _cutting.limit(queryLimit).get(),
        _sewing.limit(queryLimit).get(),
        _production.limit(queryLimit).get(),
        _issue.limit(queryLimit).get(),
        _export.limit(queryLimit).get(),
        _users.limit(queryLimit).get(),
      ]);
      final masterLc = results[0].docs.map((d) => d.data());
      final po = results[1].docs.map((d) => d.data());
      final cutting = results[2].docs.map((d) => d.data());
      final sewing = results[3].docs.map((d) => d.data());
      final production = results[4].docs.map((d) => d.data());
      final issue = results[5].docs.map((d) => d.data());
      final export = results[6].docs.map((d) => d.data());
      final users = results[7].docs.map((d) => d.data());

      return Right(
        DashboardStatsEntity(
          masterLcCount: results[0].docs.length,
          masterLcValue: _sum(masterLc, 'masterLcValue'),
          poCount: results[1].docs.length,
          poValue: _sum(po, 'poValue'),
          cuttingCount: results[2].docs.length,
          cuttingQuantity: _sum(cutting, 'cuttingQuantity').toInt(),
          sewingCount: results[3].docs.length,
          sewingQuantity: _sum(sewing, 'sewingQuantity').toInt(),
          productionCount: results[4].docs.length,
          // `quantity` is Production's canonical stored field; older records
          // created before it existed carry only `productionValue`.
          productionQuantity: _sum(production, 'quantity').toInt(),
          issueCount: results[5].docs.length,
          issueQuantity: _sum(issue, 'issueQuantity').toInt(),
          exportCount: results[6].docs.length,
          exportQuantity: _sum(export, 'exportQuantity').toInt(),
          userCount: results[7].docs.length,
          activeUserCount: users
              .where((d) => _bool(d['isActive'], fallback: true))
              .length,
        ),
      );
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  // ----------------------------------------------------------- activities

  @override
  Future<Either<String, List<DashboardActivityEntity>>> getRecentActivities(
    int limit,
  ) async {
    try {
      final results = await Future.wait([
        _latestActivity(_masterLc, 'createdAt', 'master_lc'),
        _latestActivity(_po, 'createdAt', 'purchase_order'),
        _latestActivity(_cutting, 'cuttingDate', 'cutting'),
        _latestActivity(_sewing, 'sewingDate', 'sewing'),
        _latestActivity(_production, 'productionDate', 'production'),
        _latestActivity(_issue, 'issueDate', 'issue'),
        _latestActivity(_export, 'exportDate', 'export'),
      ]);
      final merged = results.expand((entries) => entries).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Right(merged.take(limit).toList());
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Reads the three newest documents of one collection and maps them to feed
  /// entries. A collection whose date field is absent simply contributes none,
  /// so one malformed collection cannot blank the whole feed.
  Future<List<DashboardActivityEntity>> _latestActivity(
    CollectionReference<Map<String, dynamic>> collection,
    String dateField,
    String module,
  ) async {
    try {
      final snapshot = await collection
          .orderBy(dateField, descending: true)
          .limit(3)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return DashboardActivityEntity(
          id: doc.id,
          module: module,
          action: 'created',
          description: _describe(module, data),
          timestamp: _date(data[dateField]) ?? DateTime.now(),
          userId: _text(data['entryPerson']),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  static String _describe(String module, Map<String, dynamic> data) =>
      switch (module) {
        'master_lc' =>
          'New Master LC: ${_text(data['tagNo'], fallback: 'Untitled')}',
        'purchase_order' =>
          'New Purchase Order: ${_text(data['poNo'], fallback: 'Untitled')}',
        'cutting' => 'Cutting entry: ${_int(data['cuttingQuantity'])} pcs',
        'sewing' => 'Sewing entry: ${_int(data['sewingQuantity'])} pcs',
        'production' => 'Production entry: ${_int(data['quantity'])} pcs',
        'issue' => 'Issue entry: ${_int(data['issueQuantity'])} pcs',
        'export' => 'Export entry: ${_int(data['exportQuantity'])} pcs',
        _ => 'New record',
      };

  // ----------------------------------------------------------- quick stats

  @override
  Future<Either<String, DashboardQuickStatsEntity>> getQuickStats() async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfWeek = startOfToday.subtract(
        Duration(days: startOfToday.weekday - 1),
      );
      final startOfMonth = DateTime(now.year, now.month);

      final results = await Future.wait([
        _totalsSince(startOfToday),
        _totalsSince(startOfWeek),
        _totalsSince(startOfMonth),
      ]);
      return Right(
        DashboardQuickStatsEntity(
          todayQuantity: results[0].quantity,
          todayValue: results[0].value,
          weekQuantity: results[1].quantity,
          weekValue: results[1].value,
          monthQuantity: results[2].quantity,
          monthValue: results[2].value,
        ),
      );
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Quantity and value totals for every stage dated on or after [from].
  Future<_Totals> _totalsSince(DateTime from) async {
    final stamp = Timestamp.fromDate(from);
    final results = await Future.wait([
      _totalsFor(_cutting, 'cuttingDate', 'cuttingQuantity', stamp),
      _totalsFor(_sewing, 'sewingDate', 'sewingQuantity', stamp),
      _totalsFor(_production, 'productionDate', 'quantity', stamp),
      _totalsFor(_issue, 'issueDate', 'issueQuantity', stamp),
      _totalsFor(_export, 'exportDate', 'exportQuantity', stamp),
    ]);
    return _Totals(
      quantity: results.fold(0, (running, t) => running + t.quantity),
      value: results.fold(0.0, (running, t) => running + t.value),
    );
  }

  /// Sums one stage's quantity column since [from]. Like the activity reader,
  /// a stage whose index or field is missing contributes zero rather than
  /// failing the whole panel.
  Future<_Totals> _totalsFor(
    CollectionReference<Map<String, dynamic>> collection,
    String dateField,
    String quantityField,
    Timestamp from,
  ) async {
    try {
      final snapshot = await collection
          .where(dateField, isGreaterThanOrEqualTo: from)
          .limit(queryLimit)
          .get();
      final docs = snapshot.docs.map((d) => d.data());
      return _Totals(quantity: _sum(docs, quantityField).toInt());
    } catch (_) {
      return const _Totals();
    }
  }

  // --------------------------------------------------------------- trends

  @override
  Future<Either<String, List<MultiSeriesDataPoint>>> getProductionTrend(
    int days,
  ) async {
    try {
      final now = DateTime.now();
      final from = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: days - 1));
      final stamp = Timestamp.fromDate(from);

      final results = await Future.wait([
        _dailySeries(_cutting, 'cuttingDate', 'cuttingQuantity', stamp),
        _dailySeries(_sewing, 'sewingDate', 'sewingQuantity', stamp),
        _dailySeries(_production, 'productionDate', 'quantity', stamp),
        _dailySeries(_issue, 'issueDate', 'issueQuantity', stamp),
        _dailySeries(_export, 'exportDate', 'exportQuantity', stamp),
      ]);

      // Seed every day in the window so the chart keeps a continuous x-axis
      // even on days with no activity.
      final points = <MultiSeriesDataPoint>[];
      for (var i = 0; i < days; i++) {
        final day = from.add(Duration(days: i));
        final key = _dayKey(day);
        points.add(
          MultiSeriesDataPoint(
            label: DateFormat('dd MMM').format(day),
            series: {
              for (var s = 0; s < _trendSeries.length; s++)
                _trendSeries[s]: results[s][key] ?? 0,
            },
          ),
        );
      }
      return Right(points);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Groups one stage's quantity by calendar day for records on or after [from].
  Future<Map<String, double>> _dailySeries(
    CollectionReference<Map<String, dynamic>> collection,
    String dateField,
    String quantityField,
    Timestamp from,
  ) async {
    try {
      final snapshot = await collection
          .where(dateField, isGreaterThanOrEqualTo: from)
          .limit(queryLimit)
          .get();
      final grouped = <String, double>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date = _date(data[dateField]);
        if (date == null) continue;
        final key = _dayKey(date);
        grouped[key] = (grouped[key] ?? 0) + _double(data[quantityField]);
      }
      return grouped;
    } catch (_) {
      return const {};
    }
  }

  // -------------------------------------------------------------- factory

  @override
  Future<Either<String, List<ChartDataPoint>>> getFactoryComparison() async {
    try {
      final results = await Future.wait([
        _factoryTotals(_cutting, 'cuttingQuantity'),
        _factoryTotals(_sewing, 'sewingQuantity'),
        _factoryTotals(_production, 'quantity'),
      ]);
      final merged = <String, double>{};
      for (final grouped in results) {
        grouped.forEach((factory, total) {
          merged[factory] = (merged[factory] ?? 0) + total;
        });
      }
      final points =
          merged.entries
              .where((e) => e.value > 0)
              .map((e) => ChartDataPoint(label: e.key, value: e.value))
              .toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      return Right(points.take(8).toList());
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  Future<Map<String, double>> _factoryTotals(
    CollectionReference<Map<String, dynamic>> collection,
    String quantityField,
  ) async {
    try {
      final snapshot = await collection.limit(queryLimit).get();
      final grouped = <String, double>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final factory = _text(data['factoryName'], fallback: 'Unassigned');
        grouped[factory] =
            (grouped[factory] ?? 0) + _double(data[quantityField]);
      }
      return grouped;
    } catch (_) {
      return const {};
    }
  }

  // --------------------------------------------------------- distribution

  @override
  Future<Either<String, List<ChartDataPoint>>> getModuleDistribution() async {
    try {
      final stats = await getStats();
      return stats.fold(Left.new, (s) {
        final counts = <String, int>{
          'Master LC': s.masterLcCount,
          'Purchase Order': s.poCount,
          'Cutting': s.cuttingCount,
          'Sewing': s.sewingCount,
          'Production': s.productionCount,
          'Issue': s.issueCount,
          'Export': s.exportCount,
        };
        final total = counts.values.fold(0, (running, v) => running + v);
        if (total == 0) return const Right(<ChartDataPoint>[]);
        final points =
            counts.entries
                .where((e) => e.value > 0)
                .map(
                  (e) => ChartDataPoint(
                    label: e.key,
                    // Stored as a percentage so the pie's slice labels and the
                    // legend share one number.
                    value: (e.value / total) * 100,
                  ),
                )
                .toList()
              ..sort((a, b) => b.value.compareTo(a.value));
        return Right(points);
      });
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  // ----------------------------------------------------------- comparison

  @override
  Future<Either<String, ComparisonRangeEntity>> getComparisonData({
    required String collection,
    required String dateField,
    required String quantityField,
    required DateTime fromDate,
    required DateTime toDate,
    required String label,
    required String department,
  }) async {
    try {
      // Callers may omit the field name for a stage whose canonical column is
      // `quantity`; fall back to it rather than querying a blank field.
      final quantityKey = quantityField.isEmpty ? 'quantity' : quantityField;
      final stampFrom = Timestamp.fromDate(fromDate);
      // Include the whole of the final day.
      final stampTo = Timestamp.fromDate(
        DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59),
      );

      final snapshot = await _db
          .collection(collection)
          .where(dateField, isGreaterThanOrEqualTo: stampFrom)
          .where(dateField, isLessThanOrEqualTo: stampTo)
          .limit(queryLimit)
          .get();

      // Month buckets keyed by sortable `yyyy-MM-01` so ordering needs no date
      // map.
      final grouped = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date = _date(data[dateField]);
        if (date == null) continue;
        final key = _monthKeyIso(date);
        grouped[key] =
            (grouped[key] ?? 0) + _readQuantity(data, quantityKey);
      }

      final months = grouped.keys.toList()..sort();
      final monthly = months
          .map(
            (key) => MonthlyDataPoint(
              month: monthKey(DateTime.parse(key)),
              monthDate: DateTime.parse(key),
              quantity: grouped[key] ?? 0,
            ),
          )
          .toList();

      return Right(
        ComparisonRangeEntity(
          label: label,
          department: department,
          fromDate: fromDate,
          toDate: toDate,
          totalQuantity: grouped.values.fold(0, (running, v) => running + v),
          monthlyData: monthly,
        ),
      );
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Reads a quantity defensively.
  ///
  /// Several collections persist a canonical field *and* a legacy `quantity`
  /// alias, and imported rows may carry numbers as strings, so the named field
  /// is tried first, then `quantity`, then zero.
  static int _readQuantity(Map<String, dynamic> data, String field) {
    final value = data[field] ?? data['quantity'] ?? 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim()) ?? 0;
  }

  // ------------------------------------------------------------- parsing

  /// Sums a numeric field across records, coercing strings and ignoring nulls.
  static double _sum(Iterable<Map<String, dynamic>> docs, String field) =>
      docs.fold(0.0, (running, doc) => running + _double(doc[field]));

  static double _double(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static int _int(Object? value) => _double(value).toInt();

  static String _text(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static bool _bool(Object? value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return fallback;
  }

  /// Accepts Firestore [Timestamp], [DateTime] or an ISO string.
  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _dayKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  static String _monthKeyIso(DateTime date) =>
      DateFormat('yyyy-MM-01').format(date);

  /// Display form of a month, e.g. `Sep 2026`.
  static String monthKey(DateTime date) => DateFormat('MMM yyyy').format(date);
}

/// Internal running total used by [_totalsSince].
class _Totals {
  const _Totals({this.quantity = 0, this.value = 0});
  final int quantity;
  final double value;
}

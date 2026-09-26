/// ============================================================================
/// ফাইল: lib/data/repositories/finished_goods_report_repository.dart
/// স্তর: Data Repository | মডিউল: ERP Common
/// উদ্দেশ্য: ERP Common data query, transaction, pagination ও persistence বাস্তবায়ন করে।
/// প্রধান অংশ: FinishedGoodsReportRepository, _LineKey
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/reports/finished_goods_report_entity.dart';
import '../../domain/repositories/i_finished_goods_report_repository.dart';

/// Builds the Finished Goods Report from Firestore.
///
/// Mirrors the Google Sheet formula: the visible lines are the distinct
/// (poNo, article, color) triplets seen in the Issue (FG In) and Export (FG Out)
/// entries, either before the range (opening balance) or inside it.
///
/// Delivery is sourced from the existing `exports` collection — it already
/// records goods leaving the FG warehouse (`exportDate` + `quantity`), so no
/// separate `deliveries` collection is needed.
///
/// Queries are kept index-light: each date range narrows one collection and the
/// line matching happens locally, so the report also works before the composite
/// indexes finish building.
class FinishedGoodsReportRepository implements IFinishedGoodsReportRepository {
  FinishedGoodsReportRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _issues =>
      _db.collection(AppConstants.collectionIssue);
  CollectionReference<Map<String, dynamic>> get _exports =>
      _db.collection(AppConstants.collectionExport);

  /// Per-query cap so a wide date range cannot pull an unbounded result set.
  static const int _queryLimit = 1000;

  @override
  Future<Either<String, List<FinishedGoodsReportEntity>>> getFinishedGoodsReport({
    required DateTime fromDate,
    required DateTime toDate,
    String search = '',
  }) async {
    try {
      final rows = await _buildRows(
        fromDate: fromDate,
        toDate: toDate,
        search: search,
      );
      return Right(rows);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, FinishedGoodsReportSummary>> getReportSummary({
    required DateTime fromDate,
    required DateTime toDate,
    String search = '',
  }) async {
    try {
      final rows = await _buildRows(
        fromDate: fromDate,
        toDate: toDate,
        search: search,
      );
      return Right(FinishedGoodsReportSummary.fromRows(rows));
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Reads the four source slices, discovers the distinct lines, then folds each
  /// line's opening balance / FG In / FG Out.
  Future<List<FinishedGoodsReportEntity>> _buildRows({
    required DateTime fromDate,
    required DateTime toDate,
    required String search,
  }) async {
    final from = _dayStart(fromDate);
    final to = _dayEnd(toDate);
    final epoch = DateTime(1970);

    // The opening balance needs everything strictly before `from`; the movement
    // columns need the range itself.
    final issueBefore = await _inRange(_issues, 'issueDate', epoch, from, true);
    final exportBefore = await _inRange(
      _exports,
      'exportDate',
      epoch,
      from,
      true,
    );
    final issueInRange = await _inRange(_issues, 'issueDate', from, to, false);
    final exportInRange = await _inRange(
      _exports,
      'exportDate',
      from,
      to,
      false,
    );

    // Distinct lines across all four slices.
    final keys = <String, _LineKey>{};
    void collect(Iterable<Map<String, dynamic>> docs) {
      for (final data in docs) {
        final key = _LineKey.fromData(data);
        if (key.isEmpty) continue;
        keys.putIfAbsent(key.value, () => key);
      }
    }

    collect(issueBefore);
    collect(exportBefore);
    collect(issueInRange);
    collect(exportInRange);

    final rows = <FinishedGoodsReportEntity>[];
    for (final key in keys.values) {
      final row = FinishedGoodsReportEntity(
        po: key.poNo,
        article: key.article,
        color: key.color,
        openingBalance:
            _sumQuantity(issueBefore, key) - _sumQuantity(exportBefore, key),
        fgIn: _sumQuantity(issueInRange, key),
        fgOut: _sumQuantity(exportInRange, key),
      );
      // The sheet hides fully zeroed lines.
      if (!row.isNonZero) continue;
      if (!row.matches(search)) continue;
      rows.add(row);
    }

    rows.sort((a, b) {
      final byPo = a.po.toLowerCase().compareTo(b.po.toLowerCase());
      if (byPo != 0) return byPo;
      final byArticle = a.article.toLowerCase().compareTo(
        b.article.toLowerCase(),
      );
      if (byArticle != 0) return byArticle;
      return a.color.toLowerCase().compareTo(b.color.toLowerCase());
    });
    return rows;
  }

  /// Reads one date slice. When [exclusiveEnd] is true the upper bound is
  /// excluded, which is what the opening balance needs.
  Future<List<Map<String, dynamic>>> _inRange(
    CollectionReference<Map<String, dynamic>> collection,
    String dateField,
    DateTime from,
    DateTime to,
    bool exclusiveEnd,
  ) async {
    final upperBound = Timestamp.fromDate(to);
    final query = collection
        .where(dateField, isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .limit(_queryLimit);
    final snapshot = exclusiveEnd
        ? await query.where(dateField, isLessThan: upperBound).get()
        : await query.where(dateField, isLessThanOrEqualTo: upperBound).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Sums one line's quantity, preferring the modern field name and falling back
  /// to the legacy `quantity` alias.
  static int _sumQuantity(List<Map<String, dynamic>> docs, _LineKey key) {
    var total = 0;
    for (final data in docs) {
      if (_LineKey.fromData(data) != key) continue;
      total += _number(data['quantity'] ?? data['exportQuantity']);
    }
    return total;
  }

  static DateTime _dayStart(DateTime value) =>
      DateTime(value.year, value.month, value.day);
  static DateTime _dayEnd(DateTime value) =>
      DateTime(value.year, value.month, value.day, 23, 59, 59, 999);

  static int _number(Object? value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString().trim() ?? '') ?? 0;
}

/// Identity of a FG line: poNo + article + color, compared case-insensitively.
class _LineKey {
  const _LineKey({
    required this.poNo,
    required this.article,
    required this.color,
  });

  final String poNo;
  final String article;
  final String color;

  static _LineKey fromData(Map<String, dynamic> data) => _LineKey(
    poNo: _trim(data['poNo'] ?? data['issuePo'] ?? data['exportPo']),
    article: _trim(data['article']),
    color: _trim(data['color']),
  );

  String get value =>
      '${poNo.toLowerCase()}|${article.toLowerCase()}|'
      '${color.toLowerCase()}';

  bool get isEmpty => poNo.isEmpty || article.isEmpty || color.isEmpty;

  static String _trim(Object? value) => value?.toString().trim() ?? '';

  @override
  bool operator ==(Object other) => other is _LineKey && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

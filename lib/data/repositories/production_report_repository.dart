/// ============================================================================
/// ফাইল: lib/data/repositories/production_report_repository.dart
/// স্তর: Data Repository | মডিউল: Production/Lasting
/// উদ্দেশ্য: Production/Lasting data query, transaction, pagination ও persistence বাস্তবায়ন করে।
/// প্রধান অংশ: ProductionReportRepository, _LineKey
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/reports/production_report_entity.dart';
import '../../domain/repositories/i_production_report_repository.dart';

/// Builds the Production Report from Firestore.
///
/// Mirrors the Google Sheet formula: the visible lines are the distinct
/// (poNo, article, color) triplets seen in the Cutting / Sewing / Production
/// entries inside the date range, enriched with company / project / ordered
/// quantity from the Purchase Orders, and summed per stage.
///
/// Queries are kept index-light: the date range narrows each collection and the
/// line matching happens locally, so the report also works before the composite
/// indexes finish building.
class ProductionReportRepository implements IProductionReportRepository {
  ProductionReportRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _cuts =>
      _db.collection(AppConstants.collectionCutting);
  CollectionReference<Map<String, dynamic>> get _sews =>
      _db.collection(AppConstants.collectionSewing);
  CollectionReference<Map<String, dynamic>> get _lasts =>
      _db.collection(AppConstants.collectionProduction);
  CollectionReference<Map<String, dynamic>> get _pos =>
      _db.collection(AppConstants.collectionPO);

  /// Per-query cap so a wide date range cannot pull an unbounded result set.
  static const int _queryLimit = 1000;

  @override
  Future<Either<String, List<ProductionReportEntity>>> getProductionReport({
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
  Future<Either<String, ProductionReportSummary>> getReportSummary({
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
      return Right(ProductionReportSummary.fromRows(rows));
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Reads the three source collections once, discovers the distinct lines, then
  /// resolves each line's PO metadata, ordered quantity and per-stage totals.
  Future<List<ProductionReportEntity>> _buildRows({
    required DateTime fromDate,
    required DateTime toDate,
    required String search,
  }) async {
    final from = _dayStart(fromDate);
    final to = _dayEnd(toDate);

    final cutDocs = await _inRange(_cuts, 'cuttingDate', from, to);
    final sewDocs = await _inRange(_sews, 'sewingDate', from, to);
    final lastDocs = await _inRange(_lasts, 'productionDate', from, to);

    // Distinct lines across all three sources.
    final keys = <String, _LineKey>{};
    void collect(Iterable<Map<String, dynamic>> docs) {
      for (final data in docs) {
        final key = _LineKey.fromData(data);
        if (key.isEmpty) continue;
        keys.putIfAbsent(key.value, () => key);
      }
    }

    collect(cutDocs);
    collect(sewDocs);
    collect(lastDocs);

    // PO master data, loaded once per distinct PO No.
    final poCache = <String, Map<String, dynamic>>{};
    for (final poNo in keys.values.map((k) => k.poNo).toSet()) {
      final snapshot = await _pos
          .where('poNo', isEqualTo: poNo)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        poCache[poNo.toLowerCase()] = snapshot.docs.first.data();
      }
    }

    final rows = <ProductionReportEntity>[];
    for (final key in keys.values) {
      final po = poCache[key.poNo.toLowerCase()] ?? const <String, dynamic>{};
      final row = ProductionReportEntity(
        company: _string(po['company']),
        project: _string(po['project']),
        po: key.poNo,
        article: key.article,
        color: key.color,
        poQuantity: _lineOrderQuantity(po, key.article, key.color),
        cuttingQuantity: _sumStage(cutDocs, key, 'cuttingQuantity'),
        sewingQuantity: _sumStage(sewDocs, key, 'sewingQuantity'),
        lastingQuantity: _sumStage(lastDocs, key, 'quantity'),
      );
      if (row.matches(search)) rows.add(row);
    }

    // Stable, sheet-like ordering.
    rows.sort((a, b) {
      final byCompany = a.company.compareTo(b.company);
      if (byCompany != 0) return byCompany;
      final byProject = a.project.compareTo(b.project);
      if (byProject != 0) return byProject;
      final byPo = a.po.compareTo(b.po);
      if (byPo != 0) return byPo;
      final byArticle = a.article.compareTo(b.article);
      return byArticle != 0 ? byArticle : a.color.compareTo(b.color);
    });
    return rows;
  }

  Future<List<Map<String, dynamic>>> _inRange(
    CollectionReference<Map<String, dynamic>> collection,
    String dateField,
    DateTime from,
    DateTime to,
  ) async {
    final snapshot = await collection
        .where(dateField, isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where(dateField, isLessThanOrEqualTo: Timestamp.fromDate(to))
        .limit(_queryLimit)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Sums one stage's quantity for a line, preferring the modern field name and
  /// falling back to the legacy `quantity` alias.
  static int _sumStage(
    List<Map<String, dynamic>> docs,
    _LineKey key,
    String field,
  ) {
    var total = 0;
    for (final data in docs) {
      if (_LineKey.fromData(data) != key) continue;
      total += _number(data[field] ?? data['quantity']);
    }
    return total;
  }

  /// Ordered quantity for the PO line, from `lineItems` or the legacy flat
  /// `poQuantity` field.
  static int _lineOrderQuantity(
    Map<String, dynamic> po,
    String article,
    String color,
  ) {
    final items = po['lineItems'];
    if (items is List && items.isNotEmpty) {
      final normalizedArticle = article.trim().toLowerCase();
      final normalizedColor = color.trim().toLowerCase();
      var total = 0;
      for (final raw in items) {
        if (raw is! Map) continue;
        final itemArticle = _string(raw['article']).toLowerCase();
        final itemColor = _string(raw['color']).toLowerCase();
        if (itemArticle == normalizedArticle && itemColor == normalizedColor) {
          total += _number(raw['poQuantity'] ?? raw['quantity']);
        }
      }
      // Fall back to the whole order when the line is not itemised.
      if (total > 0) return total;
      return items.fold<int>(
        0,
        (total, raw) => total +
            _number(raw is Map ? raw['poQuantity'] ?? raw['quantity'] : null),
      );
    }
    return _number(po['poQuantity'] ?? po['quantity']);
  }

  static DateTime _dayStart(DateTime value) =>
      DateTime(value.year, value.month, value.day);
  static DateTime _dayEnd(DateTime value) =>
      DateTime(value.year, value.month, value.day, 23, 59, 59, 999);

  static int _number(Object? value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString().trim() ?? '') ?? 0;

  static String _string(Object? value) => value?.toString().trim() ?? '';
}

/// Identity of a PO line: poNo + article + color, compared case-insensitively.
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
    poNo: _trim(data['poNo']),
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


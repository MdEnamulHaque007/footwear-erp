/// ============================================================================
/// ফাইল: lib/data/repositories/warehouse_report_repository.dart
/// স্তর: Data Repository | মডিউল: ERP Common
/// উদ্দেশ্য: ERP Common data query, transaction, pagination ও persistence বাস্তবায়ন করে।
/// প্রধান অংশ: WarehouseReportRepository, _Stage
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/reports/warehouse_report_entity.dart';
import '../../domain/repositories/i_warehouse_report_repository.dart';

class WarehouseReportRepository implements IWarehouseReportRepository {
  WarehouseReportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _limit = 1000;
  final FirebaseFirestore _firestore;

  @override
  Future<Either<String, WarehouseReportResult>> getWarehouseReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
      final to = DateTime(
        toDate.year,
        toDate.month,
        toDate.day,
        23,
        59,
        59,
        999,
      );
      final results = await Future.wait([
        _fetchCollection(AppConstants.collectionPO),
        _fetchInRange(AppConstants.collectionCutting, 'cuttingDate', from, to),
        _fetchInRange(AppConstants.collectionSewing, 'sewingDate', from, to),
        _fetchInRange(
          AppConstants.collectionProduction,
          'productionDate',
          from,
          to,
        ),
      ]);

      final rows = <String, WarehouseReportRow>{};
      _addStage(rows, results[1], _Stage.cutting);
      _addStage(rows, results[2], _Stage.sewing);
      _addStage(rows, results[3], _Stage.lasting);
      _mergePurchaseOrders(rows, results[0]);

      final ordered = rows.values.toList()
        ..sort((left, right) {
          var value = _compare(left.company, right.company);
          if (value != 0) {
            return value;
          }
          value = _compare(left.project, right.project);
          if (value != 0) {
            return value;
          }
          value = _compare(left.poNo, right.poNo);
          if (value != 0) {
            return value;
          }
          value = _compare(left.article, right.article);
          return value != 0 ? value : _compare(left.color, right.color);
        });

      return Right(
        WarehouseReportResult(
          rows: ordered,
          summary: WarehouseReportSummary.fromRows(ordered),
          fromDate: from,
          toDate: toDate,
        ),
      );
    } on FirebaseException catch (error) {
      return Left('Failed to load report: ${error.message ?? error.code}');
    } catch (error) {
      return Left('Failed to load report: $error');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCollection(String collection) async {
    final snapshot = await _firestore.collection(collection).limit(_limit).get();
    return snapshot.docs.map((document) => document.data()).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchInRange(
    String collection,
    String dateField,
    DateTime from,
    DateTime to,
  ) async {
    final snapshot = await _firestore
        .collection(collection)
        .where(dateField, isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where(dateField, isLessThanOrEqualTo: Timestamp.fromDate(to))
        .limit(_limit)
        .get();
    return snapshot.docs.map((document) => document.data()).toList();
  }

  void _addStage(
    Map<String, WarehouseReportRow> rows,
    List<Map<String, dynamic>> documents,
    _Stage stage,
  ) {
    for (final data in documents) {
      final row = _emptyRow(data);
      if (!_isValidKey(row)) {
        continue;
      }
      final previous = rows[row.lineKey] ?? row;
      final quantity = switch (stage) {
        _Stage.cutting => _number(data['cuttingQuantity'] ?? data['quantity']),
        _Stage.sewing => _number(data['sewingQuantity'] ?? data['quantity']),
        _Stage.lasting => _number(data['quantity'] ?? data['productionQuantity']),
      };
      rows[row.lineKey] = switch (stage) {
        _Stage.cutting => previous.copyWith(
          cuttingQuantity: previous.cuttingQuantity + quantity,
        ),
        _Stage.sewing => previous.copyWith(
          sewingQuantity: previous.sewingQuantity + quantity,
        ),
        _Stage.lasting => previous.copyWith(
          lastingQuantity: previous.lastingQuantity + quantity,
        ),
      };
    }
  }

  void _mergePurchaseOrders(
    Map<String, WarehouseReportRow> rows,
    List<Map<String, dynamic>> purchaseOrders,
  ) {
    for (final po in purchaseOrders) {
      final base = _emptyRow(po);
      final lineItems = po['lineItems'];
      if (lineItems is List && lineItems.isNotEmpty) {
        for (final raw in lineItems.whereType<Map>()) {
          final item = Map<String, dynamic>.from(raw);
          final row = base.copyWith(
            article: _string(item['article'] ?? item['articleNo']),
            color: _string(item['color'] ?? item['colour']),
          );
          _mergePoLine(
            rows,
            row,
            _number(item['poQuantity'] ?? item['quantity']),
          );
        }
      } else {
        _mergePoLine(
          rows,
          base,
          _number(po['totalQuantity'] ?? po['poQuantity'] ?? po['quantity']),
        );
      }
    }
  }

  void _mergePoLine(
    Map<String, WarehouseReportRow> rows,
    WarehouseReportRow poRow,
    int quantity,
  ) {
    if (!_isValidKey(poRow)) {
      return;
    }
    final key = rows.containsKey(poRow.lineKey)
        ? poRow.lineKey
        : _findMatchingPoLine(rows, poRow);
    if (key == null) {
      return;
    }
    final previous = rows[key];
    if (previous == null) {
      return;
    }
    rows[key] = previous.copyWith(
      company: previous.company.isEmpty ? poRow.company : previous.company,
      project: previous.project.isEmpty ? poRow.project : previous.project,
      poQuantity: previous.poQuantity + quantity,
    );
  }

  String? _findMatchingPoLine(
    Map<String, WarehouseReportRow> rows,
    WarehouseReportRow poRow,
  ) {
    for (final entry in rows.entries) {
      final row = entry.value;
      if (_compare(row.poNo, poRow.poNo) == 0 &&
          _compare(row.article, poRow.article) == 0 &&
          _compare(row.color, poRow.color) == 0) {
        return entry.key;
      }
    }
    return null;
  }

  WarehouseReportRow _emptyRow(Map<String, dynamic> data) => WarehouseReportRow(
    company: _string(data['company']),
    project: _string(data['project']),
    poNo: _string(data['poNo']),
    article: _string(data['article'] ?? data['articleNo']),
    color: _string(data['color'] ?? data['colour']),
    poQuantity: 0,
    cuttingQuantity: 0,
    sewingQuantity: 0,
    lastingQuantity: 0,
  );

  static bool _isValidKey(WarehouseReportRow row) =>
      row.poNo.isNotEmpty && row.article.isNotEmpty && row.color.isNotEmpty;

  static int _compare(String left, String right) =>
      left.toLowerCase().compareTo(right.toLowerCase());

  static String _string(Object? value) => value?.toString().trim() ?? '';

  static int _number(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return double.tryParse(value?.toString().replaceAll(',', '').trim() ?? '')
            ?.toInt() ??
        0;
  }
}

enum _Stage { cutting, sewing, lasting }

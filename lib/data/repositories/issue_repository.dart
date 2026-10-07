/// ============================================================================
/// ফাইল: lib/data/repositories/issue_repository.dart
/// স্তর: Data Repository | মডিউল: Finished Goods Issue
/// উদ্দেশ্য: Finished Goods Issue data query, transaction, pagination ও persistence বাস্তবায়ন করে।
/// প্রধান অংশ: IssueRepository, _IssueValidationException
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../core/services/firebase/firestore_query_paging.dart';
import '../../core/services/activity/activity_log_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firebase/firebase_cloud_function_service.dart';

import 'package:dartz/dartz.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/repositories/i_issue_repository.dart';
import '../models/issue/issue_model.dart';
import '../models/purchase_order/po_model.dart';

class IssueRepository implements IIssueRepository {
  IssueRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(AppConstants.collectionIssue);
  CollectionReference<Map<String, dynamic>> get _productionCollection =>
      _db.collection(AppConstants.collectionProduction);
  CollectionReference<Map<String, dynamic>> get _poCollection =>
      _db.collection(AppConstants.collectionPO);

  /// Keyset-pagination cursor: reset on page 0, advanced to the last doc read.
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  @override
  Future<Either<String, List<IssueModel>>> getIssueList({
    int page = 0,
    int limit = 20,
  }) async {
    return ActivityLogService.instance
        .trackRead<Either<String, List<IssueModel>>>(
          module: 'issue',
          operation: 'getIssueList',
          documentId: '',
          body: () async {
            try {
              if (page == 0) _lastDoc = null;
              var query = _collection.orderBy('issueDate', descending: true);
              if (page > 0 && _lastDoc != null) {
                query = query.startAfterDocument(_lastDoc!);
              }
              final snapshot = await query.limit(limit).get();
              if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;
              return Right(snapshot.docs.map(IssueModel.fromSnapshot).toList());
            } on FirebaseException catch (e) {
              return Left('Database error: ${e.message}');
            } catch (_) {
              return const Left('An unexpected error occurred');
            }
          },
        );
  }

  @override
  Future<Either<String, List<IssueModel>>> byPoTag(String poTagNo) async {
    return ActivityLogService.instance
        .trackRead<Either<String, List<IssueModel>>>(
          module: 'issue',
          operation: 'byPoTag',
          documentId: '',
          body: () async {
            try {
              final snapshot = await _collection
                  .where('tagNo', isEqualTo: poTagNo)
                  .orderBy('sl')
                  .get();
              return Right(snapshot.docs.map(IssueModel.fromSnapshot).toList());
            } on FirebaseException catch (e) {
              return Left('Database error: ${e.message}');
            } catch (_) {
              return const Left('An unexpected error occurred');
            }
          },
        );
  }

  @override
  Future<Either<String, IssueModel?>> byId(String id) async {
    return ActivityLogService.instance.trackRead<Either<String, IssueModel?>>(
      module: 'issue',
      operation: 'byId',
      documentId: id,
      body: () async {
        try {
          final snapshot = await _collection.doc(id).get();
          return Right(
            snapshot.exists ? IssueModel.fromSnapshot(snapshot) : null,
          );
        } on FirebaseException catch (e) {
          return Left('Database error: ${e.message}');
        } catch (_) {
          return const Left('An unexpected error occurred');
        }
      },
    );
  }

  @override
  Future<Either<String, List<IssueModel>>> byLine({
    required String poNo,
    required String article,
    required String color,
  }) async {
    return ActivityLogService.instance
        .trackRead<Either<String, List<IssueModel>>>(
          module: 'issue',
          operation: 'byLine',
          documentId: '',
          body: () async {
            try {
              // Index-independent: Article and Color are filtered locally so the detail
              // view also works before composite indexes finish building in Firestore.
              final snapshot = await _collection
                  .where('poNo', isEqualTo: poNo)
                  .getAll();
              final normalizedArticle = _normalize(article);
              final normalizedColor = _normalize(color);
              final entries =
                  snapshot.docs
                      .map(IssueModel.fromSnapshot)
                      .where(
                        (item) =>
                            _normalize(item.article) == normalizedArticle &&
                            _normalize(item.color) == normalizedColor,
                      )
                      .toList()
                    ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
              return Right(entries);
            } on FirebaseException catch (e) {
              return Left('Database error: ${e.message}');
            } catch (_) {
              return const Left('An unexpected error occurred');
            }
          },
        );
  }

  /// Distinct PO No list taken from the Production entries.
  ///
  /// Issue is only valid for a PO that has actually been produced.
  @override
  Future<Either<String, List<String>>> getProductionEntryPONoList() async {
    return ActivityLogService.instance.trackRead<Either<String, List<String>>>(
      module: 'issue',
      operation: 'getProductionEntryPONoList',
      documentId: '',
      body: () async {
        try {
          final snapshot = await _productionCollection.getAll();
          final poNos =
              snapshot.docs
                  .map((doc) => _string(doc.data()['poNo']))
                  .where((poNo) => poNo.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          return Right(poNos);
        } on FirebaseException catch (e) {
          return Left('Database error: ${e.message}');
        } catch (_) {
          return const Left('An unexpected error occurred');
        }
      },
    );
  }

  /// Distinct Article + Color pairs recorded in the Production entries of
  /// [poNo], deduped case-insensitively (first casing wins).
  @override
  Future<Either<String, List<ProductionLine>>> getProductionEntryLines(
    String poNo,
  ) async {
    return ActivityLogService.instance
        .trackRead<Either<String, List<ProductionLine>>>(
          module: 'issue',
          operation: 'getProductionEntryLines',
          documentId: '',
          body: () async {
            try {
              final snapshot = await _productionCollection
                  .where('poNo', isEqualTo: poNo)
                  .getAll();
              final lines = <String, ProductionLine>{};
              for (final doc in snapshot.docs) {
                final data = doc.data();
                final article = _string(data['article']);
                final color = _string(data['color']);
                if (article.isEmpty || color.isEmpty) continue;
                final key = '${article.toLowerCase()}|${color.toLowerCase()}';
                lines.putIfAbsent(
                  key,
                  () => ProductionLine(article: article, color: color),
                );
              }
              final result = lines.values.toList()
                ..sort((a, b) {
                  final byArticle = a.article.toLowerCase().compareTo(
                    b.article.toLowerCase(),
                  );
                  return byArticle != 0
                      ? byArticle
                      : a.color.toLowerCase().compareTo(b.color.toLowerCase());
                });
              return Right(result);
            } on FirebaseException catch (e) {
              return Left('Database error: ${e.message}');
            } catch (_) {
              return const Left('An unexpected error occurred');
            }
          },
        );
  }

  @override
  Future<Either<String, POModel?>> poByNo(String poNo) async {
    return ActivityLogService.instance.trackRead<Either<String, POModel?>>(
      module: 'issue',
      operation: 'poByNo',
      documentId: '',
      body: () async {
        try {
          final snapshot = await _poCollection
              .where('poNo', isEqualTo: poNo)
              .limit(1)
              .get();
          return Right(
            snapshot.docs.isEmpty
                ? null
                : POModel.fromSnapshot(snapshot.docs.first),
          );
        } on FirebaseException catch (e) {
          return Left('Database error: ${e.message}');
        } catch (_) {
          return const Left('An unexpected error occurred');
        }
      },
    );
  }

  @override
  Future<int> getCumulativeProductionQty({
    required String poNo,
    required String article,
    required String color,
    required DateTime upToDate,
    String? excludeId,
  }) async {
    return ActivityLogService.instance.trackRead<int>(
      module: 'issue',
      operation: 'getCumulativeProductionQty',
      documentId: '',
      body: () async {
        final snapshot = await _productionCollection
            .where('poNo', isEqualTo: poNo)
            .getAll();
        final cutoff = DateTime(upToDate.year, upToDate.month, upToDate.day);
        return snapshot.docs
            .where((doc) => doc.id != excludeId)
            .where((doc) {
              final data = doc.data();
              return _normalize(data['article']) == _normalize(article) &&
                  _normalize(data['color']) == _normalize(color);
            })
            .where((doc) {
              final date = _date(doc.data()['productionDate']);
              if (date == null) return true;
              return !DateTime(date.year, date.month, date.day).isAfter(cutoff);
            })
            .fold<int>(
              0,
              (total, doc) => total + _productionQuantity(doc.data()),
            );
      },
    );
  }

  @override
  Future<int> getCumulativeIssueQty({
    required String poNo,
    required String article,
    required String color,
    String? excludeId,
  }) async {
    return ActivityLogService.instance.trackRead<int>(
      module: 'issue',
      operation: 'getCumulativeIssueQty',
      documentId: '',
      body: () async {
        final snapshot = await _collection
            .where('poNo', isEqualTo: poNo)
            .getAll();
        return _cumulativeIssue(
          snapshot.docs,
          article: article,
          color: color,
          excludingId: excludeId,
        );
      },
    );
  }

  @override
  Future<int> getCumulativeIssueQuantity({
    required String poTagNo,
    required DateTime upToDate,
    String? excludingId,
  }) async {
    return ActivityLogService.instance.trackRead<int>(
      module: 'issue',
      operation: 'getCumulativeIssueQuantity',
      documentId: '',
      body: () async {
        final snapshot = await _collection
            .where('tagNo', isEqualTo: poTagNo)
            .getAll();
        final cutoff = DateTime(upToDate.year, upToDate.month, upToDate.day);
        return snapshot.docs
            .where((doc) => doc.id != excludingId)
            .where((doc) {
              final date = _date(doc.data()['issueDate']);
              if (date == null) return true;
              return !DateTime(date.year, date.month, date.day).isAfter(cutoff);
            })
            .fold<int>(0, (total, doc) => total + _quantity(doc.data()));
      },
    );
  }

  @override
  Future<Either<String, void>> createWithTransaction(IssueEntity item) =>
      _writeWithTransaction(item, isUpdate: false);

  @override
  Future<Either<String, void>> updateWithTransaction(IssueEntity item) =>
      _writeWithTransaction(item, isUpdate: true);

  /// Authorization, quantity/date checks and writes run in one server transaction.
  Future<Either<String, void>> _writeWithTransaction(
    IssueEntity item, {
    required bool isUpdate,
  }) async {
    if (isUpdate && (item.id == null || item.id!.isEmpty)) {
      return const Left('Record ID is required for update');
    }
    final id = isUpdate ? item.id! : _collection.doc().id;
    return FirebaseCloudFunctionService.instance.mutate(
      collection: 'issues',
      action: isUpdate ? 'update' : 'create',
      id: id,
      data: IssueModel.fromEntity(item).toFirestore(),
    );
  }

  @override
  Future<Either<String, void>> createIssue(IssueEntity item) =>
      _writeWithTransaction(item, isUpdate: false);

  @override
  Future<Either<String, void>> update(IssueEntity item) =>
      _writeWithTransaction(item, isUpdate: true);

  @override
  Future<Either<String, void>> delete(String id) => FirebaseCloudFunctionService
      .instance
      .mutate(collection: 'issues', action: 'delete', id: id);

  /// Sums Issue records for one PO line, optionally skipping a document.
  static int _cumulativeIssue(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required String article,
    required String color,
    String? excludingId,
  }) {
    final normalizedArticle = _normalize(article);
    final normalizedColor = _normalize(color);
    return docs
        .where((doc) => doc.id != excludingId)
        .where((doc) {
          final data = doc.data();
          return _normalize(data['article']) == normalizedArticle &&
              _normalize(data['color']) == normalizedColor;
        })
        .fold<int>(0, (total, doc) => total + _quantity(doc.data()));
  }

  static int _quantity(Map<String, dynamic> data) =>
      _number(data['quantity'] ?? data['issueQuantity']);

  static int _productionQuantity(Map<String, dynamic> data) =>
      _number(data['quantity'] ?? data['productionQuantity']);

  static int _number(Object? value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString().trim() ?? '') ?? 0;

  static String _normalize(Object? value) =>
      value?.toString().trim().toLowerCase() ?? '';

  static String _string(Object? value) => value?.toString().trim() ?? '';

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

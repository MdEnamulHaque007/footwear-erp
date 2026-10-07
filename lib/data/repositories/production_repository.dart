/// ============================================================================
/// ফাইল: lib/data/repositories/production_repository.dart
/// স্তর: Data Repository | মডিউল: Production/Lasting
/// উদ্দেশ্য: Production/Lasting data query, transaction, pagination ও persistence বাস্তবায়ন করে।
/// প্রধান অংশ: ProductionRepository, _ProductionValidationException
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
import '../../domain/entities/production_entity.dart';
import '../../domain/repositories/i_production_repository.dart';
import '../models/production/production_model.dart';
import '../models/purchase_order/po_model.dart';

class ProductionRepository implements IProductionRepository {
  ProductionRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(AppConstants.collectionProduction);
  CollectionReference<Map<String, dynamic>> get _sewingCollection =>
      _db.collection(AppConstants.collectionSewing);
  CollectionReference<Map<String, dynamic>> get _cuttingCollection =>
      _db.collection(AppConstants.collectionCutting);
  CollectionReference<Map<String, dynamic>> get _poCollection =>
      _db.collection(AppConstants.collectionPO);

  /// Keyset-pagination cursor: reset on page 0, advanced to the last doc read.
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  @override
  Future<Either<String, List<ProductionModel>>> getProductionList({
    int page = 0,
    int limit = 20,
  }) async {
    return ActivityLogService.instance
        .trackRead<Either<String, List<ProductionModel>>>(
          module: 'production',
          operation: 'getProductionList',
          documentId: '',
          body: () async {
            try {
              if (page == 0) _lastDoc = null;
              var query = _collection.orderBy(
                'productionDate',
                descending: true,
              );
              if (page > 0 && _lastDoc != null) {
                query = query.startAfterDocument(_lastDoc!);
              }
              final snapshot = await query.limit(limit).get();
              if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;
              return Right(
                snapshot.docs.map(ProductionModel.fromSnapshot).toList(),
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
  Future<Either<String, List<ProductionModel>>> byPoTag(String poTagNo) async {
    return ActivityLogService.instance
        .trackRead<Either<String, List<ProductionModel>>>(
          module: 'production',
          operation: 'byPoTag',
          documentId: '',
          body: () async {
            try {
              final snapshot = await _collection
                  .where('tagNo', isEqualTo: poTagNo)
                  .orderBy('sl')
                  .get();
              return Right(
                snapshot.docs.map(ProductionModel.fromSnapshot).toList(),
              );
            } on FirebaseException catch (e) {
              return Left('Database error: ${e.message}');
            } catch (_) {
              return const Left('An unexpected error occurred');
            }
          },
        );
  }

  /// Distinct PO No list taken from the Sewing entries.
  ///
  /// Production is only valid for a PO that has actually been sewn, so the
  /// Production form's PO dropdown is sourced from `sewings` rather than from
  /// the full Purchase Order collection.
  @override
  Future<Either<String, List<String>>> getSewingEntryPONoList() async {
    return ActivityLogService.instance.trackRead<Either<String, List<String>>>(
      module: 'production',
      operation: 'getSewingEntryPONoList',
      documentId: '',
      body: () async {
        try {
          final snapshot = await _sewingCollection.getAll();
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

  /// Distinct PO No list taken from the Cutting entries.
  @override
  Future<Either<String, List<String>>> getCuttingEntryPONoList() async {
    return ActivityLogService.instance.trackRead<Either<String, List<String>>>(
      module: 'production',
      operation: 'getCuttingEntryPONoList',
      documentId: '',
      body: () async {
        try {
          final snapshot = await _cuttingCollection.getAll();
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

  /// Distinct Article + Color pairs recorded in the Sewing entries of [poNo].
  ///
  /// Deduplicated case-insensitively on the trimmed values (the same article can
  /// be stored as `Art-A` / `art-a` / `Art-A `) while preserving the original
  /// casing of the first occurrence for display.
  @override
  Future<Either<String, List<SewingLine>>> getSewingEntryLines(
    String poNo,
  ) async {
    return ActivityLogService.instance
        .trackRead<Either<String, List<SewingLine>>>(
          module: 'production',
          operation: 'getSewingEntryLines',
          documentId: '',
          body: () async {
            try {
              final snapshot = await _sewingCollection
                  .where('poNo', isEqualTo: poNo)
                  .getAll();
              final lines = <String, SewingLine>{};
              for (final doc in snapshot.docs) {
                final data = doc.data();
                final article = _string(data['article']);
                final color = _string(data['color']);
                if (article.isEmpty || color.isEmpty) continue;
                // Case-insensitive key keeps only the first (original-case) occurrence.
                final key = '${article.toLowerCase()}|${color.toLowerCase()}';
                lines.putIfAbsent(
                  key,
                  () => SewingLine(article: article, color: color),
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
      module: 'production',
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
  Future<Either<String, ProductionModel?>> byId(String id) async {
    return ActivityLogService.instance
        .trackRead<Either<String, ProductionModel?>>(
          module: 'production',
          operation: 'byId',
          documentId: id,
          body: () async {
            try {
              final snapshot = await _collection.doc(id).get();
              return Right(
                snapshot.exists ? ProductionModel.fromSnapshot(snapshot) : null,
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
  Future<Either<String, List<ProductionModel>>> byLine({
    required String poNo,
    required String article,
    required String color,
  }) async {
    return ActivityLogService.instance
        .trackRead<Either<String, List<ProductionModel>>>(
          module: 'production',
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
                      .map(ProductionModel.fromSnapshot)
                      .where(
                        (item) =>
                            _normalize(item.article) == normalizedArticle &&
                            _normalize(item.color) == normalizedColor,
                      )
                      .toList()
                    ..sort(
                      (a, b) => b.productionDate.compareTo(a.productionDate),
                    );
              return Right(entries);
            } on FirebaseException catch (e) {
              return Left('Database error: ${e.message}');
            } catch (_) {
              return const Left('An unexpected error occurred');
            }
          },
        );
  }

  @override
  Future<int> getCumulativeProductionQuantity({
    required String poTagNo,
    required DateTime upToDate,
  }) async {
    return ActivityLogService.instance.trackRead<int>(
      module: 'production',
      operation: 'getCumulativeProductionQuantity',
      documentId: '',
      body: () async {
        final snapshot = await _collection
            .where('tagNo', isEqualTo: poTagNo)
            .where(
              'productionDate',
              isLessThanOrEqualTo: Timestamp.fromDate(upToDate),
            )
            .get();
        return snapshot.docs.fold<int>(
          0,
          (total, doc) => total + _quantity(doc.data()),
        );
      },
    );
  }

  @override
  Future<int> getCumulativeProductionQty({
    required String poNo,
    required String article,
    required String color,
    String? excludeId,
  }) async {
    return ActivityLogService.instance.trackRead<int>(
      module: 'production',
      operation: 'getCumulativeProductionQty',
      documentId: '',
      body: () async {
        final snapshot = await _collection
            .where('poNo', isEqualTo: poNo)
            .getAll();
        return _cumulative(
          snapshot.docs,
          article: article,
          color: color,
          excludingId: excludeId,
        );
      },
    );
  }

  @override
  Future<Either<String, void>> createWithTransaction(ProductionEntity item) =>
      _writeWithTransaction(item, isUpdate: false);

  @override
  Future<Either<String, void>> updateWithTransaction(ProductionEntity item) =>
      _writeWithTransaction(item, isUpdate: true);

  /// Authorization, quantity/date checks and writes run in one server transaction.
  Future<Either<String, void>> _writeWithTransaction(
    ProductionEntity item, {
    required bool isUpdate,
  }) async {
    if (isUpdate && (item.id == null || item.id!.isEmpty)) {
      return const Left('Record ID is required for update');
    }
    final id = isUpdate ? item.id! : _collection.doc().id;
    return FirebaseCloudFunctionService.instance.mutate(
      collection: 'productions',
      action: isUpdate ? 'update' : 'create',
      id: id,
      data: ProductionModel.fromEntity(item).toFirestore(),
    );
  }

  @override
  Future<Either<String, void>> createProduction(ProductionEntity item) =>
      _writeWithTransaction(item, isUpdate: false);

  @override
  Future<Either<String, void>> update(ProductionEntity item) =>
      _writeWithTransaction(item, isUpdate: true);

  @override
  Future<Either<String, void>> delete(String id) => FirebaseCloudFunctionService
      .instance
      .mutate(collection: 'productions', action: 'delete', id: id);

  /// Sums Production records for one PO line, optionally skipping a document.
  static int _cumulative(
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
      _number(data['quantity'] ?? data['productionQuantity']);

  /// Reads the sewing quantity, falling back to the legacy `quantity` alias.
  static int _sewingQuantity(Map<String, dynamic> data) =>
      _number(data['sewingQuantity'] ?? data['quantity']);

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

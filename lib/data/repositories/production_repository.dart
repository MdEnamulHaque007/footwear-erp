import 'package:cloud_firestore/cloud_firestore.dart';
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
    try {
      if (page == 0) _lastDoc = null;
      var query = _collection.orderBy('productionDate', descending: true);
      if (page > 0 && _lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      final snapshot = await query.limit(limit).get();
      if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;
      return Right(snapshot.docs.map(ProductionModel.fromSnapshot).toList());
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, List<ProductionModel>>> byPoTag(String poTagNo) async {
    try {
      final snapshot = await _collection
          .where('tagNo', isEqualTo: poTagNo)
          .orderBy('sl')
          .get();
      return Right(snapshot.docs.map(ProductionModel.fromSnapshot).toList());
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Distinct PO No list taken from the Sewing entries.
  ///
  /// Production is only valid for a PO that has actually been sewn, so the
  /// Production form's PO dropdown is sourced from `sewings` rather than from
  /// the full Purchase Order collection.
  @override
  Future<Either<String, List<String>>> getSewingEntryPONoList() async {
    try {
      final snapshot = await _sewingCollection.limit(1000).get();
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
  }

  /// Distinct PO No list taken from the Cutting entries.
  @override
  Future<Either<String, List<String>>> getCuttingEntryPONoList() async {
    try {
      final snapshot = await _cuttingCollection.limit(1000).get();
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
    try {
      final snapshot = await _sewingCollection
          .where('poNo', isEqualTo: poNo)
          .limit(1000)
          .get();
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
  }

  @override
  Future<Either<String, POModel?>> poByNo(String poNo) async {
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
  }

  @override
  Future<Either<String, ProductionModel?>> byId(String id) async {
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
  }

  @override
  Future<Either<String, List<ProductionModel>>> byLine({
    required String poNo,
    required String article,
    required String color,
  }) async {
    try {
      // Index-independent: Article and Color are filtered locally so the detail
      // view also works before composite indexes finish building in Firestore.
      final snapshot = await _collection
          .where('poNo', isEqualTo: poNo)
          .limit(1000)
          .get();
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
            ..sort((a, b) => b.productionDate.compareTo(a.productionDate));
      return Right(entries);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<int> getCumulativeProductionQuantity({
    required String poTagNo,
    required DateTime upToDate,
  }) async {
    final snapshot = await _collection
        .where('tagNo', isEqualTo: poTagNo)
        .where('productionDate', isLessThanOrEqualTo: Timestamp.fromDate(upToDate))
        .get();
    return snapshot.docs.fold<int>(
      0,
      (total, doc) => total + _quantity(doc.data()),
    );
  }

  @override
  Future<int> getCumulativeProductionQty({
    required String poNo,
    required String article,
    required String color,
    String? excludeId,
  }) async {
    final snapshot = await _collection
        .where('poNo', isEqualTo: poNo)
        .limit(1000)
        .get();
    return _cumulative(snapshot.docs, article: article, color: color,
        excludingId: excludeId);
  }


  @override
  Future<Either<String, void>> createWithTransaction(ProductionEntity item) =>
      _writeWithTransaction(item, isUpdate: false);

  @override
  Future<Either<String, void>> updateWithTransaction(ProductionEntity item) =>
      _writeWithTransaction(item, isUpdate: true);

  /// Validation + atomic write.
  ///
  /// The availability snapshot (Sewing completed on or before the production
  /// date − Production already recorded for the same PO line) is computed with
  /// the date-filtered cumulative queries, validated, then the document is
  /// written inside a `runTransaction` that re-reads the persisted record, so a
  /// concurrent edit cannot silently over-consume the Sewing balance.
  Future<Either<String, void>> _writeWithTransaction(
    ProductionEntity item, {
    required bool isUpdate,
  }) async {
    final ref = isUpdate && item.id != null
        ? _collection.doc(item.id)
        : _collection.doc();
    try {
      // 1. Cumulative Sewing for this PO line, completed on or before the
      // selected production date.
      final sewingQty = await _cumulativeSewing(
        poTagNo: item.tagNo,
        poNo: item.poNo,
        article: item.article,
        color: item.color,
        upToDate: item.productionDate,
      );

      // 2. Production already booked against the same PO line.
      final producedQty = item.poNo.isEmpty
          ? await _cumulativeProductionByTag(
              poTagNo: item.tagNo,
              excludingId: ref.id,
            )
          : await getCumulativeProductionQty(
              poNo: item.poNo,
              article: item.article,
              color: item.color,
              excludeId: ref.id,
            );

      // 3. Validate.
      final available = sewingQty - producedQty;
      if (item.quantity <= 0) {
        return const Left('Quantity must be greater than zero');
      }
      if (item.quantity > available) {
        return Left(
          'Production quantity exceeds available sewing quantity '
          '(available: $available)',
        );
      }

      // 4. Atomic write.
      final data = ProductionModel.fromEntity(item).toFirestore();
      await _db.runTransaction<void>((transaction) async {
        if (isUpdate) {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw const _ProductionValidationException(
              'Production record no longer exists',
            );
          }
          transaction.update(ref, data);
        } else {
          transaction.set(ref, data);
        }
      });
      return const Right(null);
    } on _ProductionValidationException catch (e) {
      return Left(e.message);
    } on FirebaseException catch (e) {
      return Left(
        '${isUpdate ? 'Failed to update' : 'Failed to create'}: ${e.message}',
      );
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> createProduction(ProductionEntity item) async {
    try {
      final ref = _collection.doc();
      final data = ProductionModel.fromEntity(item).toFirestore();
      await ref.set(data);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left('Failed to create: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> update(ProductionEntity item) async {
    try {
      final data = ProductionModel.fromEntity(item).toFirestore();
      data['updatedAt'] = Timestamp.now();
      await _collection.doc(item.id).update(data);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left('Failed to update: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> delete(String id) async {
    try {
      await _collection.doc(id).delete();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left('Failed to delete: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Cumulative Sewing quantity for the PO line up to [upToDate].
  ///
  /// Filtered by `poNo`/`article`/`color` when the entry carries a PO line
  /// (the PO-driven flow) and by `poTagNo` otherwise, so legacy records keep
  /// validating against their tag.
  Future<int> _cumulativeSewing({
    required String poTagNo,
    required String poNo,
    required String article,
    required String color,
    required DateTime upToDate,
  }) async {
    if (poNo.isEmpty) {
      final snapshot = await _sewingCollection
          .where('tagNo', isEqualTo: poTagNo)
          .where(
            'sewingDate',
            isLessThanOrEqualTo: Timestamp.fromDate(upToDate),
          )
          .get();
      return snapshot.docs.fold<int>(
        0,
        (total, doc) => total + _sewingQuantity(doc.data()),
      );
    }
    final snapshot = await _sewingCollection
        .where('poNo', isEqualTo: poNo)
        .limit(1000)
        .get();
    final cutoff = DateTime(upToDate.year, upToDate.month, upToDate.day);
    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          return _normalize(data['article']) == _normalize(article) &&
              _normalize(data['color']) == _normalize(color);
        })
        .where((doc) {
          final date = _date(doc.data()['sewingDate']);
          if (date == null) return true;
          return !DateTime(date.year, date.month, date.day).isAfter(cutoff);
        })
        .fold<int>(0, (total, doc) => total + _sewingQuantity(doc.data()));
  }

  /// Cumulative Production for one PO tag, optionally skipping a document.
  Future<int> _cumulativeProductionByTag({
    required String poTagNo,
    String? excludingId,
  }) async {
    final snapshot = await _collection
        .where('tagNo', isEqualTo: poTagNo)
        .limit(1000)
        .get();
    return snapshot.docs
        .where((doc) => doc.id != excludingId)
        .fold<int>(0, (total, doc) => total + _quantity(doc.data()));
  }

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

  static int _quantity(Map<String, dynamic> data) => _number(
    data['quantity'] ?? data['productionQuantity'],
  );

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

/// Internal marker so a failed transaction validation is surfaced to the user
/// verbatim instead of being wrapped in a generic Firestore error message.
class _ProductionValidationException implements Exception {
  const _ProductionValidationException(this.message);
  final String message;
}

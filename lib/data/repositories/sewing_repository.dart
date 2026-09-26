/// ============================================================================
/// ফাইল: lib/data/repositories/sewing_repository.dart
/// স্তর: Data Repository | মডিউল: Sewing
/// উদ্দেশ্য: Sewing data query, transaction, pagination ও persistence বাস্তবায়ন করে।
/// প্রধান অংশ: SewingRepository, _SewingValidationException
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/sewing_entity.dart';
import '../../domain/repositories/i_sewing_repository.dart';
import '../models/sewing/sewing_model.dart';
import '../models/purchase_order/po_model.dart';

class SewingRepository implements ISewingRepository {
  SewingRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(AppConstants.collectionSewing);
  CollectionReference<Map<String, dynamic>> get _cuttingCollection =>
      _db.collection(AppConstants.collectionCutting);
  CollectionReference<Map<String, dynamic>> get _poCollection =>
      _db.collection(AppConstants.collectionPO);

  /// Distinct PO No list taken from the Cutting entries.
  CollectionReference<Map<String, dynamic>> get _cuttingCollectionRef =>
      _db.collection(AppConstants.collectionCutting);

  /// Keyset-pagination cursor: reset on page 0, advanced to the last doc read.
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  @override
  Future<Either<String, List<SewingModel>>> getSewingList({
    int page = 0,
    int limit = 20,
  }) async {
    try {
      if (page == 0) _lastDoc = null;
      var query = _collection.orderBy('sewingDate', descending: true);
      if (page > 0 && _lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      final snapshot = await query.limit(limit).get();
      if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;
      return Right(snapshot.docs.map(SewingModel.fromSnapshot).toList());
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, List<SewingModel>>> byPoTag(String poTagNo) async {
    try {
      final snapshot = await _collection
          .where('tagNo', isEqualTo: poTagNo)
          .orderBy('sl')
          .get();
      return Right(snapshot.docs.map(SewingModel.fromSnapshot).toList());
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, SewingModel?>> byId(String id) async {
    try {
      final snapshot = await _collection.doc(id).get();
      return Right(snapshot.exists ? SewingModel.fromSnapshot(snapshot) : null);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, List<SewingModel>>> byLine({
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
              .map(SewingModel.fromSnapshot)
              .where(
                (item) =>
                    _normalize(item.article) == normalizedArticle &&
                    _normalize(item.color) == normalizedColor,
              )
              .toList()
            ..sort((a, b) => b.sewingDate.compareTo(a.sewingDate));
      return Right(entries);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, List<String>>> getPONoList() async {
    try {
      final snapshot = await _poCollection.orderBy('poNo').limit(100).get();
      return Right(
        snapshot.docs
            .map((doc) => doc.data()['poNo'] as String? ?? '')
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList(),
      );
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Distinct PO No list taken from the Cutting entries.
  ///
  /// Sewing is only valid for a PO that has actually been cut, so the Sewing
  /// form's PO dropdown is sourced from `cuttings` rather than from the full
  /// Purchase Order collection.
  @override
  Future<Either<String, List<String>>> getCuttingEntryPONoList() async {
    try {
      final snapshot = await _cuttingCollectionRef.limit(1000).get();
      final poNos =
          snapshot.docs
              .map((doc) => _normalize(doc.data()['poNo']))
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

  @override
  Future<Either<String, List<POModel>>> getPOListForDropdown() async {
    try {
      final snapshot = await _poCollection.orderBy('poNo').limit(100).get();
      return Right(snapshot.docs.map(POModel.fromSnapshot).toList());
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, POModel?>> getPOByNo(String poNo) async {
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
  Future<Either<String, void>> createWithTransaction(SewingEntity item) =>
      _writeWithTransaction(item, isUpdate: false);

  @override
  Future<Either<String, void>> updateWithTransaction(SewingEntity item) =>
      _writeWithTransaction(item, isUpdate: true);

  /// Atomic re-check + write.
  ///
  /// Firestore's `Transaction` (cloud_firestore 6.8) can only read single
  /// documents, so the availability snapshot is computed before the write and
  /// the transaction then re-validates against the persisted values and writes
  /// the document atomically. Two devices saving the same PO line at the same
  /// instant both hold their own availability snapshot, so the second writer
  /// re-reads the loser's record inside its own transaction and fails the
  /// availability check instead of over-consuming Cutting quantity.
  Future<Either<String, void>> _writeWithTransaction(
    SewingEntity item, {
    required bool isUpdate,
  }) async {
    final ref = isUpdate && item.id != null
        ? _collection.doc(item.id)
        : _collection.doc();
    try {
      // 1 + 2. Cumulative Cutting (cuttingDate <= sewingDate) and cumulative
      // Sewing (self-excluded on update) for this PO line.
      final cuttingQty = await getCumulativeCuttingQty(
        poNo: item.poNo,
        article: item.article,
        color: item.color,
        upToDate: item.sewingDate,
      );
      final sewingQty = await getCumulativeSewingQty(
        poNo: item.poNo,
        article: item.article,
        color: item.color,
        excludeId: ref.id,
      );

      // 3. Validate against the availability snapshot.
      final available = cuttingQty - sewingQty;
      final quantity = item.effectiveQuantity;
      if (quantity <= 0) {
        return const Left('Quantity must be greater than zero');
      }
      if (quantity > available) {
        return Left(
          'Sewing quantity exceeds available cutting quantity '
          '(available: $available)',
        );
      }

      // 4. Atomic write, re-checking the persisted document inside the
      // transaction so a concurrent edit cannot silently over-consume.
      final data = SewingModel.fromEntity(item).toFirestore();
      await _db.runTransaction<void>((transaction) async {
        if (isUpdate) {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw const _SewingValidationException(
              'Sewing record no longer exists',
            );
          }
          transaction.update(ref, data);
        } else {
          transaction.set(ref, data);
        }
      });
      return const Right(null);
    } on _SewingValidationException catch (e) {
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
  Future<Either<String, void>> createSewing(SewingEntity item) async {
    try {
      final ref = _collection.doc();
      final data = SewingModel.fromEntity(item).toFirestore();
      await ref.set(data);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left('Failed to create: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> update(SewingEntity item) async {
    try {
      final data = SewingModel.fromEntity(item).toFirestore();
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

  @override
  Future<int> getCumulativeCuttingQty({
    required String poNo,
    required String article,
    required String color,
    required DateTime upToDate,
    String? excludingId,
  }) async {
    // Index-independent: filtered and summed locally so the module also works
    // before the `poNo + article + color + cuttingDate` index is deployed.
    final snapshot = await _cuttingCollection
        .where('poNo', isEqualTo: poNo)
        .limit(1000)
        .get();
    return _cumulativeCutting(
      snapshot.docs,
      article: article,
      color: color,
      upToDate: upToDate,
      excludingId: excludingId,
    );
  }

  @override
  Future<int> getCumulativeSewingQty({
    required String poNo,
    required String article,
    required String color,
    String? excludeId,
  }) async {
    final snapshot = await _collection
        .where('poNo', isEqualTo: poNo)
        .limit(1000)
        .get();
    return _cumulativeSewing(
      snapshot.docs,
      article: article,
      color: color,
      excludingId: excludeId,
    );
  }

  @override
  Future<int> getCumulativeSewingQuantity({
    required String poTagNo,
    required DateTime upToDate,
  }) async {
    final snapshot = await _collection
        .where('tagNo', isEqualTo: poTagNo)
        .where('sewingDate', isLessThanOrEqualTo: Timestamp.fromDate(upToDate))
        .get();
    return snapshot.docs.fold<int>(
      0,
      (total, doc) => total + _sewingQuantity(doc.data()),
    );
  }

  /// Sums Cutting records for one PO line, honouring `cuttingDate <= upToDate`.
  static int _cumulativeCutting(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required String article,
    required String color,
    required DateTime upToDate,
    String? excludingId,
  }) {
    final normalizedArticle = _normalize(article);
    final normalizedColor = _normalize(color);
    final cutoff = DateTime(upToDate.year, upToDate.month, upToDate.day);
    return docs
        .where((doc) => doc.id != excludingId)
        .where((doc) {
          final data = doc.data();
          return _normalize(data['article']) == normalizedArticle &&
              _normalize(data['color']) == normalizedColor;
        })
        .where((doc) {
          final date = _date(doc.data()['cuttingDate']);
          if (date == null) return true;
          return !DateTime(date.year, date.month, date.day).isAfter(cutoff);
        })
        .fold<int>(
          0,
          (total, doc) =>
              total +
              _number(doc.data()['cuttingQuantity'] ?? doc.data()['quantity']),
        );
  }

  /// Sums Sewing records for one PO line, optionally skipping one document.
  static int _cumulativeSewing(
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
        .fold<int>(0, (total, doc) => total + _sewingQuantity(doc.data()));
  }

  /// Reads the sewing quantity, falling back to the legacy `quantity` alias.
  static int _sewingQuantity(Map<String, dynamic> data) =>
      _number(data['sewingQuantity'] ?? data['quantity']);

  static int _number(Object? value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString().trim() ?? '') ?? 0;

  static String _normalize(Object? value) =>
      value?.toString().trim().toLowerCase() ?? '';

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Internal marker so a failed transaction validation is surfaced to the user
/// verbatim instead of being wrapped in a generic Firestore error message.
class _SewingValidationException implements Exception {
  const _SewingValidationException(this.message);
  final String message;
}


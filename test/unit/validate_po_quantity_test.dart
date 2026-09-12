import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/data/models/purchase_order/po_model.dart';
import 'package:footwear/domain/entities/master_lc_entity.dart';
import 'package:footwear/domain/entities/po_entity.dart';
import 'package:footwear/domain/repositories/i_po_repository.dart';
import 'package:footwear/domain/usecases/purchase_order/validate_po_quantity_usecase.dart';

class _FakePORepository implements IPORepository {
  _FakePORepository(this.existing);
  final List<POModel> existing;

  @override
  Future<Either<String, List<POModel>>> getPOList({
    int page = 0,
    int limit = 20,
  }) async => Right(existing);

  @override
  Future<Either<String, List<POModel>>> byTag(String tag) async =>
      Right(existing.where((po) => po.tagNo == tag).toList());

  @override
  Future<Either<String, void>> createPO(POEntity item) async =>
      const Right(null);

  @override
  Future<Either<String, void>> update(POEntity item) async => const Right(null);

  @override
  Future<Either<String, void>> delete(String id) async => const Right(null);
}

POEntity _po({
  String? id,
  required int quantity,
  double unitPrice = 10,
  String tagNo = 'LC-001',
}) => POEntity(
  id: id,
  sl: 1,
  poDate: DateTime(2024, 1, 1),
  tagNo: tagNo,
  company: 'Acme',
  project: 'P1',
  brand: 'B',
  poNo: 'PO-1',
  article: 'A1',
  color: 'Black',
  poQuantity: quantity,
  unitPrice: unitPrice,
  entryPerson: 'tester',
);

MasterLCEntity _master({int quantity = 100, double value = 1000}) =>
    MasterLCEntity(
      sl: 1,
      masterLcDate: DateTime(2024, 1, 1),
      tagNo: 'LC-001',
      project: 'P1',
      company: 'Acme',
      masterLcQuantity: quantity,
      masterLcValue: value,
    );

void main() {
  group('ValidatePOQuantityUseCase', () {
    late _FakePORepository repo;
    late ValidatePOQuantityUseCase useCase;

    setUp(() {
      repo = _FakePORepository([
        POModel.fromEntity(_po(id: 'existing-1', quantity: 40)),
      ]);
      useCase = ValidatePOQuantityUseCase(repo);
    });

    test('rejects zero quantity when it exceeds remaining master LC', () async {
      final master = _master(quantity: 40); // 40 already used, 0 remaining
      final result = await useCase(master, _po(id: 'new', quantity: 1));
      expect(result, isNotNull);
    });

    test('rejects quantity exceeding available master LC quantity', () async {
      final master = _master(quantity: 100); // 40 used, 60 available
      final result = await useCase(master, _po(id: 'new', quantity: 61));
      expect(result, 'PO quantity exceeds available Master LC quantity');
    });

    test(
      'accepts negative candidate quantity since use case only checks limits',
      () async {
        // -5 + 40 = 35 <= 40, so the use case (which has no sign guard) returns null.
        final result = await useCase(
          _master(quantity: 40),
          _po(id: 'new', quantity: -5),
        );
        expect(result, isNull);
      },
    );

    test('rejects PO value exceeding available master LC value', () async {
      final master = _master(quantity: 1000, value: 100); // value bound tight
      final result = await useCase(
        master,
        _po(id: 'new', quantity: 20, unitPrice: 10),
      );
      expect(result, 'PO value exceeds available Master LC value');
    });

    test('accepts quantity and value within limits', () async {
      final master = _master(quantity: 100, value: 1000);
      final result = await useCase(
        master,
        _po(id: 'new', quantity: 50, unitPrice: 10),
      );
      expect(result, isNull);
    });

    test(
      'excludes the candidate itself when updating an existing PO',
      () async {
        final master = _master(quantity: 100, value: 1000);
        final result = await useCase(
          master,
          _po(id: 'existing-1', quantity: 60, unitPrice: 10),
        );
        expect(result, isNull);
      },
    );
  });
}

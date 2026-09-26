/// ============================================================================
/// ফাইল: test/unit/warehouse_report_test.dart
/// স্তর: Test | মডিউল: ERP Common
/// উদ্দেশ্য: Warehouse Report Test অংশের প্রত্যাশিত আচরণ স্বয়ংক্রিয়ভাবে যাচাই করে এবং regression প্রতিরোধ করে।
/// প্রধান অংশ: _FakeRepository
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:footwear/domain/entities/reports/warehouse_report_entity.dart';
import 'package:footwear/domain/repositories/i_warehouse_report_repository.dart';
import 'package:footwear/domain/usecases/reports/get_warehouse_report_usecase.dart';

void main() {
  const first = WarehouseReportRow(
    company: ' REDTAPE ',
    project: 'UPTOP',
    poNo: 'E26016',
    article: 'RSO4864',
    color: 'WHITE',
    poQuantity: 12000,
    cuttingQuantity: 4956,
    sewingQuantity: 12378,
    lastingQuantity: 12000,
  );

  test('lineKey normalizes casing and surrounding whitespace', () {
    expect(first.lineKey, 'redtape|uptop|e26016|rso4864|white');
  });

  test('summary of no rows is zero', () {
    final summary = WarehouseReportSummary.fromRows(const []);
    expect(summary.totalPoQuantity, 0);
    expect(summary.totalCuttingQuantity, 0);
    expect(summary.totalSewingQuantity, 0);
    expect(summary.totalLastingQuantity, 0);
  });

  test('summary of one row preserves every quantity', () {
    final summary = WarehouseReportSummary.fromRows([first]);
    expect(summary.totalPoQuantity, 12000);
    expect(summary.totalCuttingQuantity, 4956);
    expect(summary.totalSewingQuantity, 12378);
    expect(summary.totalLastingQuantity, 12000);
  });

  test('summary adds every quantity column independently', () {
    final second = first.copyWith(
      poNo: 'E26017',
      poQuantity: 100,
      cuttingQuantity: 20,
      sewingQuantity: 30,
      lastingQuantity: 40,
    );
    final summary = WarehouseReportSummary.fromRows([first, second]);
    expect(summary.totalPoQuantity, 12100);
    expect(summary.totalCuttingQuantity, 4976);
    expect(summary.totalSewingQuantity, 12408);
    expect(summary.totalLastingQuantity, 12040);
  });

  test('copyWith only changes the requested grouped quantity', () {
    final updated = first.copyWith(cuttingQuantity: 5000);
    expect(updated.lineKey, first.lineKey);
    expect(updated.cuttingQuantity, 5000);
    expect(updated.sewingQuantity, first.sewingQuantity);
  });

  test('line key differs when any grouping value differs', () {
    expect(first.copyWith(color: 'BLACK').lineKey, isNot(first.lineKey));
    expect(first.copyWith(article: 'RSO4865').lineKey, isNot(first.lineKey));
  });

  test('use case rejects an inverted date range', () async {
    final useCase = GetWarehouseReportUseCase(_FakeRepository());
    final result = await useCase(
      fromDate: DateTime(2026, 2, 2),
      toDate: DateTime(2026, 2, 1),
    );
    expect(
      result.fold((message) => message, (_) => ''),
      'To date must be after From date',
    );
  });

  test('use case delegates a valid date range to repository', () async {
    final repository = _FakeRepository();
    final result = await GetWarehouseReportUseCase(repository)(
      fromDate: DateTime(2026, 1, 1),
      toDate: DateTime(2026, 1, 31),
    );
    expect(result.isRight(), isTrue);
    expect(repository.called, isTrue);
  });
}

class _FakeRepository implements IWarehouseReportRepository {
  bool called = false;

  @override
  Future<Either<String, WarehouseReportResult>> getWarehouseReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    called = true;
    return Right(
      WarehouseReportResult(
        rows: const [],
        summary: WarehouseReportSummary.fromRows(const []),
        fromDate: fromDate,
        toDate: toDate,
      ),
    );
  }
}

/// ============================================================================
/// ফাইল: test/unit/validate_export_quantity_test.dart
/// স্তর: Test | মডিউল: Export
/// উদ্দেশ্য: Validate Export Quantity Test অংশের প্রত্যাশিত আচরণ স্বয়ংক্রিয়ভাবে যাচাই করে এবং regression প্রতিরোধ করে।
/// প্রধান অংশ: FakeExportRepository
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/domain/repositories/i_export_repository.dart';
import 'package:footwear/domain/usecases/export/validate_export_quantity_usecase.dart';

/// Stub repository exposing the two cumulative reads the validator depends on.
class FakeExportRepository implements IExportRepository {
  FakeExportRepository({this.issue = 0, this.exported = 0});

  /// Cumulative Issue for the PO line (already date-filtered by the repo).
  int issue;

  /// Cumulative Export for the PO line (self-excluded by the repo).
  int exported;

  DateTime? requestedUpToDate;
  String? requestedExcludeId;

  @override
  Future<int> getCumulativeIssueQty({
    required String poNo,
    required String article,
    required String color,
    required DateTime upToDate,
    String? excludeId,
  }) async {
    requestedUpToDate = upToDate;
    return issue;
  }

  @override
  Future<int> getCumulativeExportQty({
    required String poNo,
    required String article,
    required String color,
    String? excludeId,
  }) async {
    requestedExcludeId = excludeId;
    return exported;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ValidateExportQuantityUseCase', () {
    late FakeExportRepository repo;
    late ValidateExportQuantityUseCase useCase;

    setUp(() {
      repo = FakeExportRepository();
      useCase = ValidateExportQuantityUseCase(repo);
    });

    test('accepts a quantity within the available issue quantity', () async {
      repo.issue = 500;
      repo.exported = 0;
      final result = await useCase(
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        candidateQuantity: 300,
        exportDate: DateTime(2024, 7, 10),
      );
      expect(result, isNull);
    });

    test('rejects zero or negative quantity', () async {
      repo.issue = 500;
      final result = await useCase(
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        candidateQuantity: 0,
        exportDate: DateTime(2024, 7, 10),
      );
      expect(result, 'Quantity must be greater than zero');
    });

    test('rejects a quantity exceeding the remaining balance', () async {
      // 500 issued on 10 July, 300 already exported → 200 available.
      repo.issue = 500;
      repo.exported = 300;
      final result = await useCase(
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        candidateQuantity: 250,
        exportDate: DateTime(2024, 7, 10),
      );
      expect(
        result,
        contains('Export quantity exceeds available issue quantity'),
      );
      expect(result, contains('available: 200'));
    });

    test('passes the export date through as the issue cut-off', () async {
      final exportDate = DateTime(2024, 7, 10);
      await useCase(
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        candidateQuantity: 10,
        exportDate: exportDate,
      );
      expect(repo.requestedUpToDate, exportDate);
    });

    test('self-excludes the edited entry when updating', () async {
      repo.issue = 500;
      repo.exported = 200;
      final result = await useCase.validateUpdate(
        exportId: 'exp-1',
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        candidateQuantity: 300,
        exportDate: DateTime(2024, 7, 10),
      );
      expect(result, isNull);
      expect(repo.requestedExcludeId, 'exp-1');
    });

    test('availability is issue minus export', () async {
      repo.issue = 900;
      repo.exported = 250;
      final available = await useCase.availability(
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        exportDate: DateTime(2024, 7, 12),
      );
      expect(available, 650);
    });

    test('returns zero availability when no PO line is selected', () async {
      final available = await useCase.availability(
        poNo: '',
        article: '',
        color: '',
        exportDate: DateTime(2024, 7, 12),
      );
      expect(available, 0);
    });

    test('skips the repository when availability is pre-computed', () async {
      final result = await useCase(
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
        candidateQuantity: 60,
        exportDate: DateTime(2024, 7, 10),
        availableQuantity: 50,
      );
      expect(
        result,
        contains('Export quantity exceeds available issue quantity'),
      );
      expect(result, contains('available: 50'));
    });
  });
}

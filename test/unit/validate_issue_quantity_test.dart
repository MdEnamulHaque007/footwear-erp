import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/domain/repositories/i_issue_repository.dart';
import 'package:footwear/domain/usecases/issue/validate_issue_quantity_usecase.dart';

/// Stub repository exposing the two cumulative reads the validator depends on.
class FakeIssueRepository implements IIssueRepository {
  FakeIssueRepository({this.production = 0, this.issued = 0});

  /// Cumulative Production for the PO line (already date-filtered by the repo).
  int production;

  /// Cumulative Issue for the PO line (self-excluded by the repo).
  int issued;

  /// Cumulative Issue resolved by the legacy tag path.
  int issuedByTag = 0;

  DateTime? requestedUpToDate;
  String? requestedExcludeId;

  @override
  Future<int> getCumulativeProductionQty({
    required String poNo,
    required String article,
    required String color,
    required DateTime upToDate,
    String? excludeId,
  }) async {
    requestedUpToDate = upToDate;
    return production;
  }

  @override
  Future<int> getCumulativeIssueQty({
    required String poNo,
    required String article,
    required String color,
    String? excludeId,
  }) async {
    requestedExcludeId = excludeId;
    return issued;
  }

  @override
  Future<int> getCumulativeIssueQuantity({
    required String poTagNo,
    required DateTime upToDate,
    String? excludingId,
  }) async => issuedByTag;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ValidateIssueQuantityUseCase', () {
    late FakeIssueRepository repo;
    late ValidateIssueQuantityUseCase useCase;

    setUp(() {
      repo = FakeIssueRepository();
      useCase = ValidateIssueQuantityUseCase(repo);
    });

    test('accepts a quantity within the available production quantity', () async {
      repo.production = 500;
      repo.issued = 0;
      final result = await useCase(
        poTagNo: 'TAG-1',
        issueDate: DateTime(2024, 7, 10),
        candidateQuantity: 300,
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
      );
      expect(result, isNull);
    });

    test('rejects zero or negative quantity', () async {
      repo.production = 500;
      final result = await useCase(
        poTagNo: 'TAG-1',
        issueDate: DateTime(2024, 7, 10),
        candidateQuantity: 0,
      );
      expect(result, 'Quantity must be greater than zero');
    });

    test('rejects a quantity exceeding the remaining balance', () async {
      // 500 produced on 10 July, 300 already issued → 200 available.
      repo.production = 500;
      repo.issued = 300;
      final result = await useCase(
        poTagNo: 'TAG-1',
        issueDate: DateTime(2024, 7, 10),
        candidateQuantity: 250,
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
      );
      expect(
        result,
        contains('Issue quantity exceeds available production quantity'),
      );
      expect(result, contains('available: 200'));
    });

    test('passes the issue date through as the production cut-off', () async {
      final issueDate = DateTime(2024, 7, 10);
      await useCase(
        poTagNo: 'TAG-1',
        issueDate: issueDate,
        candidateQuantity: 10,
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
      );
      expect(repo.requestedUpToDate, issueDate);
    });

    test('self-excludes the edited entry when updating', () async {
      repo.production = 500;
      repo.issued = 200;
      final result = await useCase.validateUpdate(
        issueId: 'issue-1',
        poTagNo: 'TAG-1',
        issueDate: DateTime(2024, 7, 10),
        candidateQuantity: 300,
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
      );
      expect(result, isNull);
      expect(repo.requestedExcludeId, 'issue-1');
    });

    test('availability is production minus issue', () async {
      repo.production = 900;
      repo.issued = 250;
      final available = await useCase.availability(
        poTagNo: 'TAG-1',
        issueDate: DateTime(2024, 7, 10),
        poNo: 'PO-001',
        article: 'ART-1',
        color: 'RED',
      );
      expect(available, 650);
    });

    test('legacy tag path uses the caller-supplied alreadyIssued', () async {
      repo.production = 0;
      repo.issuedByTag = 50;
      final result = await useCase(
        poTagNo: 'TAG-1',
        issueDate: DateTime(2024, 7, 10),
        candidateQuantity: 30,
        alreadyIssued: 100,
      );
      // available = alreadyIssued (100) − issued (50) = 50
      expect(result, isNull);
    });

    test('skips the repository when availability is pre-computed', () async {
      final result = await useCase(
        poTagNo: 'TAG-1',
        issueDate: DateTime(2024, 7, 10),
        candidateQuantity: 60,
        availableQuantity: 50,
      );
      expect(
        result,
        contains('Issue quantity exceeds available production quantity'),
      );
      expect(result, contains('available: 50'));
    });
  });
}

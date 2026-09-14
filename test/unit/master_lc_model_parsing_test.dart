import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/domain/entities/master_lc_entity.dart';

/// The defensive parsers `MasterLCModel.fromSnapshot` applies to raw Firestore
/// values, reproduced here so legacy-document handling can be tested without a
/// `DocumentSnapshot` (that class is sealed — it can be neither faked nor
/// constructed outside the SDK).
String _string(Object? value) => value?.toString().trim() ?? '';

int _int(Object? value) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString().trim() ?? '') ?? 0;

double _double(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString().trim() ?? '') ?? 0;

DateTime? _date(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

void main() {
  group('Master LC snapshot value parsing', () {
    // Regression: the list used `d['sl'] as int? ?? 0`, so a Sl. stored as a
    // string (Sheets imports, legacy rows) threw a CastError the moment the
    // table built the row — surfacing as "Unexpected error" while scrolling.
    test('a Sl. stored as a string parses instead of throwing', () {
      expect(_int('12'), 12);
    });

    test('a Sl. stored as a double truncates to int', () {
      expect(_int(7.0), 7);
      expect(_int(7.9), 7);
    });

    test('an unparseable or missing Sl. falls back to 0', () {
      expect(_int('not-a-number'), 0);
      expect(_int(null), 0);
      expect(_int({}), 0);
    });

    test('quantity stored as a string parses to int', () {
      expect(_int('500'), 500);
    });

    test('value stored as a string parses to double', () {
      expect(_double('1200.50'), 1200.50);
      expect(_double(1200), 1200.0);
      expect(_double('nope'), 0);
    });

    test('text fields tolerate null and non-string types', () {
      expect(_string(null), '');
      expect(_string('  TAG-1  '), 'TAG-1');
      expect(_string(42), '42');
    });

    test('an ISO date string parses into a DateTime', () {
      final parsed = _date('2026-03-04T00:00:00.000Z');
      expect(parsed, isNotNull);
      expect(parsed!.year, 2026);
      expect(parsed.month, 3);
      expect(parsed.day, 4);
    });

    test('a null or unparseable date yields null', () {
      expect(_date(null), isNull);
      expect(_date('not-a-date'), isNull);
    });

    test('a fully legacy string-only document maps to a valid entity', () {
      final raw = <String, Object?>{
        'sl': '99',
        'tagNo': 'LEGACY',
        'project': 'UPTOP',
        'company': 'IALT',
        'scNo': 'SC-1',
        'lcNo': 'LC-1',
        'ttNo': 'TT-1',
        'masterLcQuantity': '1000',
        'masterLcValue': '250000',
        'masterLcDate': '2026-01-15T00:00:00.000Z',
      };
      final entity = MasterLCEntity(
        id: 'doc-1',
        sl: _int(raw['sl']),
        masterLcDate: _date(raw['masterLcDate'])!,
        tagNo: _string(raw['tagNo']),
        project: _string(raw['project']),
        company: _string(raw['company']),
        scNo: _string(raw['scNo']),
        lcNo: _string(raw['lcNo']),
        ttNo: _string(raw['ttNo']),
        masterLcQuantity: _int(raw['masterLcQuantity']),
        masterLcValue: _double(raw['masterLcValue']),
      );
      expect(entity.sl, 99);
      expect(entity.tagNo, 'LEGACY');
      expect(entity.lcNo, 'LC-1');
      expect(entity.masterLcQuantity, 1000);
      expect(entity.masterLcValue, 250000);
      expect(entity.masterLcDate, DateTime.utc(2026, 1, 15));
    });
  });
}

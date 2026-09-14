import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/domain/entities/master_lc_entity.dart';

/// Mirrors the null-safe helpers used by `MasterLCListScreen`, reproduced here
/// because the screen's are private statics and the widget needs a live bloc.
///
/// These guard the web failure `Cannot read properties of undefined (reading
/// 'Symbol(dartx.isNotEmpty)')`: a legacy document can hand the entity a
/// non-string, and calling `.toLowerCase()` / `.isEmpty` on it throws — under
/// dart2js that surfaces as a JS `undefined` error rather than a Dart
/// `NoSuchMethodError`.
bool _contains(Object? value, String lowerCaseQuery) =>
    (value?.toString() ?? '').toLowerCase().contains(lowerCaseQuery);

String _text(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

List<MasterLCEntity> _filter(List<MasterLCEntity> items, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return items;
  return items
      .where(
        (item) =>
            _contains(item.tagNo, q) ||
            _contains(item.company, q) ||
            _contains(item.project, q) ||
            _contains(item.lcNo, q) ||
            _contains(item.scNo, q) ||
            _contains(item.ttNo, q),
      )
      .toList();
}

MasterLCEntity _item({
  String tagNo = '',
  String project = '',
  String company = '',
  String lcNo = '',
  String scNo = '',
  String ttNo = '',
}) => MasterLCEntity(
  id: 'doc-1',
  sl: 1,
  masterLcDate: DateTime(2026, 1, 1),
  tagNo: tagNo,
  project: project,
  company: company,
  lcNo: lcNo,
  scNo: scNo,
  ttNo: ttNo,
  masterLcQuantity: 100,
  masterLcValue: 1000,
);

void main() {
  group('Master LC list search helpers', () {
    test('a null value does not throw', () {
      expect(_contains(null, 'x'), isFalse);
    });

    test('a non-string value is coerced instead of throwing', () {
      expect(_contains(12345, '234'), isTrue);
      expect(_text(12345), '12345');
    });

    test('an unset field falls back to the placeholder', () {
      expect(_text(null, fallback: '-'), '-');
      expect(_text('', fallback: '-'), '-');
      expect(_text('LC-1', fallback: '-'), 'LC-1');
    });

    test('an empty query returns every row', () {
      final items = [_item(tagNo: 'A'), _item(tagNo: 'B')];
      expect(_filter(items, ''), hasLength(2));
      expect(_filter(items, '   '), hasLength(2));
    });

    test('searches tagNo, company and project', () {
      final items = [
        _item(tagNo: 'TAG-50', company: 'IALT', project: 'UPTOP'),
        _item(tagNo: 'TAG-1', company: 'Bata', project: 'Bata'),
      ];
      expect(_filter(items, 'tag-50').single.tagNo, 'TAG-50');
      expect(_filter(items, 'ialt').single.tagNo, 'TAG-50');
      expect(_filter(items, 'uptop').single.tagNo, 'TAG-50');
    });

    // Regression: scNo / ttNo are visible columns but were missing from the
    // filter, so searching them silently returned nothing.
    test('searches scNo and ttNo', () {
      final items = [
        _item(tagNo: 'TAG-1', scNo: 'SC-900', ttNo: 'TT-900'),
        _item(tagNo: 'TAG-2', scNo: 'SC-1', ttNo: 'TT-1'),
      ];
      expect(_filter(items, 'sc-900').single.tagNo, 'TAG-1');
      expect(_filter(items, 'tt-900').single.tagNo, 'TAG-1');
    });

    test('matching is case-insensitive', () {
      final items = [_item(lcNo: 'LC-Abc')];
      expect(_filter(items, 'lc-abc'), hasLength(1));
      expect(_filter(items, 'LC-ABC'), hasLength(1));
    });

    test('a page loaded later is searchable', () {
      final page1 = List.generate(20, (i) => _item(tagNo: 'TAG-$i'));
      final page2 = List.generate(20, (i) => _item(tagNo: 'TAG-${i + 20}'));
      final loaded = [...page1, ...page2];
      expect(_filter(loaded, 'TAG-35').single.tagNo, 'TAG-35');
    });

    test('an unmatched query returns an empty list, not null', () {
      expect(_filter([_item(tagNo: 'A')], 'zzz'), isEmpty);
    });
  });
}

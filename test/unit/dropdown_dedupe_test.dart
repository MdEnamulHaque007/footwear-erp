/// ============================================================================
/// ফাইল: test/unit/dropdown_dedupe_test.dart
/// স্তর: Test | মডিউল: ERP Common
/// উদ্দেশ্য: Dropdown Dedupe Test অংশের প্রত্যাশিত আচরণ স্বয়ংক্রিয়ভাবে যাচাই করে এবং regression প্রতিরোধ করে।
/// প্রধান অংশ: top-level configuration ও helper declarations
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/domain/entities/production_entity.dart';

/// Mirrors the case-insensitive dedupe used by the Production/Sewing form
/// dropdowns (`_safeItems`) so the regression is covered by a unit test.
List<String> dedupe(List<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) continue;
    if (seen.add(trimmed.toLowerCase())) result.add(trimmed);
  }
  result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return result;
}

void main() {
  group('Dropdown value de-duplication', () {
    test('collapses values that differ only by case', () {
      final items = dedupe(['9522/1373/00 -34W', '9522/1373/00 -34w']);
      expect(items, ['9522/1373/00 -34W']);
    });

    test('collapses values that differ only by surrounding whitespace', () {
      final items = dedupe([' 9522/1373/00 -34W', '9522/1373/00 -34W ']);
      expect(items, ['9522/1373/00 -34W']);
    });

    test('collapses the reported duplicate case + whitespace combination', () {
      final items = dedupe([
        '9522/1373/00 -34W',
        '9522/1373/00 -34w ',
        '9522/1373/00 -34W',
      ]);
      // Exactly one DropdownMenuItem value → no assertion.
      expect(items, hasLength(1));
      expect(items.single, '9522/1373/00 -34W');
    });

    test('drops empty and whitespace-only entries', () {
      final items = dedupe(['Art-A', '', '   ', 'Art-B']);
      expect(items, ['Art-A', 'Art-B']);
    });

    test('keeps distinct values and sorts them case-insensitively', () {
      final items = dedupe(['b-article', 'Art-A', 'c-article']);
      expect(items, ['Art-A', 'b-article', 'c-article']);
    });

    test('preserves the original casing of the first occurrence', () {
      final items = dedupe(['Art-A', 'ART-A']);
      expect(items.single, 'Art-A');
    });

    test('SewingLine dedupes case-insensitively as a value type', () {
      const a = SewingLine(article: 'Art-A', color: 'RED');
      const b = SewingLine(article: 'art-a', color: 'red');
      expect(a, b);
      expect({a, b}, hasLength(1));
    });
  });
}

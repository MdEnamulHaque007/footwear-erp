/// ============================================================================
/// ফাইল: test/unit/tag_no_alias_test.dart
/// স্তর: Test | মডিউল: ERP Common
/// উদ্দেশ্য: Tag No Alias Test অংশের প্রত্যাশিত আচরণ স্বয়ংক্রিয়ভাবে যাচাই করে এবং regression প্রতিরোধ করে।
/// প্রধান অংশ: top-level configuration ও helper declarations
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/domain/entities/cutting_entity.dart';
import 'package:footwear/domain/entities/export_entity.dart';
import 'package:footwear/domain/entities/issue_entity.dart';
import 'package:footwear/domain/entities/production_entity.dart';
import 'package:footwear/domain/entities/sewing_entity.dart';

void main() {
  test('Cutting uses tagNo as the single source of truth', () {
    const item = CuttingEntity(
      voucherNo: 'C-1',
      cuttingDate: DateTime(2026, 1, 1),
      tagNo: 'TAG-1',
      poTagNo: 'DIFFERENT',
      entryPerson: 'test',
    );

    expect(item.tagNo, 'TAG-1');
    expect(item.poTagNo, item.tagNo);
  });

  test('Cutting restores tagNo from legacy poTagNo when tagNo is missing', () {
    const item = CuttingEntity(
      voucherNo: 'C-2',
      cuttingDate: DateTime(2026, 1, 1),
      poTagNo: 'LEGACY-1',
      entryPerson: 'test',
    );

    expect(item.tagNo, 'LEGACY-1');
    expect(item.poTagNo, 'LEGACY-1');
  });

  test('downstream entities expose poTagNo only as a tagNo alias', () {
    final sewing = SewingEntity(
      sl: 1,
      voucherNo: 'S-1',
      sewingDate: DateTime(2026, 1, 1),
      tagNo: 'TAG-S',
      poTagNo: 'OTHER',
      entryPerson: 'test',
    );
    const production = ProductionEntity(
      sl: 1,
      voucherNo: 'P-1',
      productionDate: DateTime(2026, 1, 1),
      tagNo: 'TAG-P',
      poTagNo: 'OTHER',
      quantity: 1,
      entryPerson: 'test',
    );
    const issue = IssueEntity(
      sl: 1,
      voucherNo: 'I-1',
      issueDate: DateTime(2026, 1, 1),
      tagNo: 'TAG-I',
      poTagNo: 'OTHER',
      quantity: 1,
      entryPerson: 'test',
    );
    const exportItem = ExportEntity(
      sl: 1,
      voucherNo: 'E-1',
      exportDate: DateTime(2026, 1, 1),
      tagNo: 'TAG-E',
      poTagNo: 'OTHER',
      quantity: 1,
      entryPerson: 'test',
    );

    expect(sewing.poTagNo, sewing.tagNo);
    expect(production.poTagNo, production.tagNo);
    expect(issue.poTagNo, issue.tagNo);
    expect(exportItem.poTagNo, exportItem.tagNo);
  });
}

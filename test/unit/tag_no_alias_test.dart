import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/domain/entities/cutting_entity.dart';
import 'package:footwear/domain/entities/export_entity.dart';
import 'package:footwear/domain/entities/issue_entity.dart';
import 'package:footwear/domain/entities/production_entity.dart';
import 'package:footwear/domain/entities/sewing_entity.dart';

void main() {
  test('Cutting uses tagNo as the single source of truth', () {
    final item = CuttingEntity(
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

  test('Sewing keeps tagNo as the single source of truth', () {
    final sewing = SewingEntity(
      sl: 1,
      voucherNo: 'S-1',
      sewingDate: DateTime(2026, 1, 1),
      tagNo: 'TAG-S',
      entryPerson: 'test',
    );
    expect(sewing.tagNo, 'TAG-S');
    expect(sewing.sewingQuantity, 0);
  });

}

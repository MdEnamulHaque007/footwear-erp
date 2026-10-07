import '../lib/domain/services/record_metrics.dart';

void expectEqual(num actual, num expected, String reason) {
  if (actual != expected)
    throw StateError('$reason: expected $expected, got $actual');
}

void main() {
  final issue = {
    'issueQuantity': 80,
    'productionQuantity': 100,
    'quantity': 80,
  };
  final export = {'exportQuantity': 30, 'issueQuantity': 80, 'quantity': 30};
  expectEqual(
    RecordMetrics.quantity('issues', issue),
    80,
    'FG In uses own quantity',
  );
  expectEqual(
    RecordMetrics.quantity('exports', export),
    30,
    'FG Out ignores upstream quantity',
  );
  expectEqual(
    RecordMetrics.quantity('issues', issue) -
        RecordMetrics.quantity('exports', export),
    50,
    'FG stock balance',
  );
  expectEqual(
    RecordMetrics.quantity('sewings', {
      'cuttingQuantity': 200,
      'sewingQuantity': 150,
    }),
    150,
    'Sewing matrix ignores Cutting availability',
  );
  expectEqual(
    RecordMetrics.quantity('productions', {
      'sewingQuantity': 150,
      'quantity': 100,
    }),
    100,
    'Production matrix ignores Sewing availability',
  );
  expectEqual(
    RecordMetrics.value('purchase_orders', {'totalValue': 200, 'poValue': 999}),
    200,
    'PO canonical value',
  );
  expectEqual(
    RecordMetrics.value('purchase_orders', {
      'lineItems': [
        {'poQuantity': '10', 'unitPrice': '2'},
        {'poQuantity': 5, 'unitPrice': 3},
      ],
    }),
    35,
    'Legacy multi-line PO value',
  );
  expectEqual(
    RecordMetrics.quantity('exports', {'quantity': '12'}),
    12,
    'Imported legacy quantity',
  );
  expectEqual(
    RecordMetrics.value('issues', {'issueQuantity': 10, 'unitPrice': 3}),
    30,
    'Missing value derives from own quantity',
  );
  print('9 production metric regression checks passed');
}

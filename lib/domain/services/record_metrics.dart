/// Collection-aware metrics: upstream availability fields must never be summed
/// as a record's own quantity (e.g. Export.issueQuantity is not FG Out).
class RecordMetrics {
  static double number(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString().trim() ?? '') ?? 0;

  static double quantity(String collection, Map<String, dynamic> data) {
    final field = switch (collection) {
      'master_lc' => 'masterLcQuantity',
      'purchase_orders' => 'totalQuantity',
      'cuttings' => 'cuttingQuantity',
      'sewings' => 'sewingQuantity',
      'productions' => 'quantity',
      'issues' => 'issueQuantity',
      'exports' => 'exportQuantity',
      _ => 'quantity',
    };
    if (data[field] != null) return number(data[field]);
    if (collection == 'purchase_orders') {
      final lines = data['lineItems'];
      if (lines is List && lines.isNotEmpty) {
        return lines.whereType<Map>().fold<double>(
          0,
          (total, line) =>
              total + number(line['poQuantity'] ?? line['quantity']),
        );
      }
      return number(data['poQuantity'] ?? data['quantity']);
    }
    return number(
      collection == 'productions'
          ? data['productionQuantity']
          : data['quantity'],
    );
  }

  static double value(String collection, Map<String, dynamic> data) {
    final field = switch (collection) {
      'master_lc' => 'masterLcValue',
      'purchase_orders' => 'totalValue',
      'cuttings' => 'cuttingValue',
      'sewings' => 'sewingValue',
      'productions' => 'productionValue',
      'issues' => 'issueValue',
      'exports' => 'exportValue',
      _ => 'value',
    };
    if (data[field] != null) return number(data[field]);
    if (collection == 'purchase_orders') {
      final lines = data['lineItems'];
      if (lines is List && lines.isNotEmpty) {
        return lines.whereType<Map>().fold<double>(
          0,
          (total, line) =>
              total +
              number(
                line['poValue'] ??
                    number(line['poQuantity'] ?? line['quantity']) *
                        number(line['unitPrice']),
              ),
        );
      }
      if (data['poValue'] != null) return number(data['poValue']);
    }
    return quantity(collection, data) * number(data['unitPrice']);
  }
}

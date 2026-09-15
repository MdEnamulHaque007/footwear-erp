import 'package:equatable/equatable.dart';

/// One comparable production stage, described by where its data lives.
///
/// The comparison panel lets the user pick any two of these and give each its
/// own date range, so the collection, date and quantity field names have to
/// travel together as data rather than being hardcoded per widget.
///
/// Firestore field names are taken from the matching `*_model.dart`
/// `toFirestore()` maps. Several collections persist a canonical field *and* a
/// legacy alias (Sewing writes both `sewingQuantity` and `quantity`), so
/// [quantityField] names the canonical one and the repository falls back to
/// `quantity` when it is absent.
class DepartmentOption extends Equatable {
  const DepartmentOption({
    required this.label,
    required this.collection,
    required this.dateField,
    required this.quantityField,
    this.valueField = '',
  });

  /// Display name, e.g. `Cutting`.
  final String label;

  /// Firestore collection, e.g. `cuttings`.
  final String collection;

  /// Field the date range filters on, e.g. `cuttingDate`.
  final String dateField;

  /// Field summed for the quantity total, e.g. `cuttingQuantity`.
  final String quantityField;

  /// Optional monetary field, e.g. `cuttingValue`. Empty when the stage has no
  /// meaningful value column.
  final String valueField;

  /// Emoji + icon per stage, so the dropdown and legend stay in step with the
  /// module palette used elsewhere on the dashboard.
  String get emoji => switch (label) {
    'Master LC' => '📄',
    'Purchase Order' => '🧾',
    'Cutting' => '✂️',
    'Sewing' => '🧵',
    'Production' => '🏭',
    'Issue' => '📦',
    'Export' => '🚢',
    _ => '📊',
  };

  /// Every comparable stage, in production-chain order.
  static const List<DepartmentOption> all = [
    DepartmentOption(
      label: 'Master LC',
      collection: 'master_lc',
      dateField: 'masterLcDate',
      quantityField: 'masterLcQuantity',
      valueField: 'masterLcValue',
    ),
    DepartmentOption(
      label: 'Purchase Order',
      collection: 'purchase_orders',
      dateField: 'poDate',
      quantityField: 'totalQuantity',
      valueField: 'totalValue',
    ),
    DepartmentOption(
      label: 'Cutting',
      collection: 'cuttings',
      dateField: 'cuttingDate',
      quantityField: 'cuttingQuantity',
    ),
    DepartmentOption(
      label: 'Sewing',
      collection: 'sewings',
      dateField: 'sewingDate',
      quantityField: 'sewingQuantity',
      valueField: 'sewingValue',
    ),
    DepartmentOption(
      label: 'Production',
      collection: 'productions',
      dateField: 'productionDate',
      quantityField: 'quantity',
      valueField: 'productionValue',
    ),
    DepartmentOption(
      label: 'Issue',
      collection: 'issues',
      dateField: 'issueDate',
      quantityField: 'issueQuantity',
      valueField: 'issueValue',
    ),
    DepartmentOption(
      label: 'Export',
      collection: 'exports',
      dateField: 'exportDate',
      quantityField: 'exportQuantity',
      valueField: 'exportValue',
    ),
  ];

  /// Looks up a stage by [label], defaulting to Cutting when unknown.
  static DepartmentOption fromLabel(String label) => all.firstWhere(
    (option) => option.label == label,
    orElse: () => all[2],
  );

  @override
  List<Object?> get props => [
    label,
    collection,
    dateField,
    quantityField,
    valueField,
  ];
}

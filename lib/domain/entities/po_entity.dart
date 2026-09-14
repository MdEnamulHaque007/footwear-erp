class POLineItemEntity {
  const POLineItemEntity({
    required this.article,
    required this.color,
    required this.poQuantity,
    required this.unitPrice,
  });

  final String article;
  final String color;
  final int poQuantity;
  final double unitPrice;
  double get poValue => poQuantity * unitPrice;
}

class POEntity {
  const POEntity({
    this.id,
    required this.sl,
    required this.poDate,
    required this.tagNo,
    required this.company,
    required this.project,
    required this.brand,
    required this.poNo,
    required this.entryPerson,
    this.lineItems = const [],
    // Legacy fields keep older callers and existing Firestore records readable.
    this.article = '',
    this.color = '',
    this.poQuantity = 0,
    this.unitPrice = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final int sl;
  final DateTime poDate;
  final String tagNo;
  final String company;
  final String project;
  final String brand;
  final String poNo;
  final String entryPerson;
  final List<POLineItemEntity> lineItems;

  final String article;
  final String color;
  final int poQuantity;
  final double unitPrice;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  List<POLineItemEntity> get effectiveLineItems => lineItems.isNotEmpty
      ? lineItems
      : [
          POLineItemEntity(
            article: article,
            color: color,
            poQuantity: poQuantity,
            unitPrice: unitPrice,
          ),
        ];

  int get totalQuantity =>
      effectiveLineItems.fold(0, (sum, item) => sum + item.poQuantity);
  double get totalValue =>
      effectiveLineItems.fold(0, (sum, item) => sum + item.poValue);
  double get poValue => totalValue;

  /// Returns a copy with the provided fields replaced.
  ///
  /// Used by [CreatePOUseCase] to normalise the Sl. to the "unassigned"
  /// sentinel before the repository allocates the real sequence number (SRS
  /// Rule 1: the Sl. is auto-generated, never caller-supplied).
  POEntity copyWith({
    String? id,
    int? sl,
    DateTime? poDate,
    String? tagNo,
    String? company,
    String? project,
    String? brand,
    String? poNo,
    String? entryPerson,
    List<POLineItemEntity>? lineItems,
  }) => POEntity(
    id: id ?? this.id,
    sl: sl ?? this.sl,
    poDate: poDate ?? this.poDate,
    tagNo: tagNo ?? this.tagNo,
    company: company ?? this.company,
    project: project ?? this.project,
    brand: brand ?? this.brand,
    poNo: poNo ?? this.poNo,
    entryPerson: entryPerson ?? this.entryPerson,
    lineItems: lineItems ?? this.lineItems,
    article: article,
    color: color,
    poQuantity: poQuantity,
    unitPrice: unitPrice,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

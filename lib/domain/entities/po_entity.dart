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
}

class CuttingEntity {
  const CuttingEntity({
    this.id,
    required this.sl,
    required this.voucherNo,
    required this.cuttingDate,
    this.poNo = '',
    this.tagNo = '',
    this.company = '',
    this.project = '',
    this.article = '',
    this.color = '',
    this.poQuantity = 0,
    this.cuttingQuantity = 0,
    String? poTagNo,
    int? quantity,
    this.factoryName = '',
    required this.entryPerson,
    this.remarks = '',
  }) : poTagNo = poTagNo ?? tagNo,
       quantity = quantity ?? cuttingQuantity;
  final String? id;
  final int sl;
  final String voucherNo;
  final DateTime cuttingDate;
  final String poNo;
  final String tagNo;
  final String company;
  final String project;
  final String article;
  final String color;
  final int poQuantity;
  final int cuttingQuantity;
  final String poTagNo;
  final int quantity;
  final String factoryName;
  final String entryPerson;
  final String remarks;
}

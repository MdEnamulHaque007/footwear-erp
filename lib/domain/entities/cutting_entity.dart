class CuttingEntity {
  const CuttingEntity({
    this.id,
    required this.sl,
    required this.voucherNo,
    required this.cuttingDate,
    required this.poTagNo,
    required this.quantity,
    required this.entryPerson,
    this.remarks = '',
  });
  final String? id;
  final int sl;
  final String voucherNo;
  final DateTime cuttingDate;
  final String poTagNo;
  final int quantity;
  final String entryPerson;
  final String remarks;
}

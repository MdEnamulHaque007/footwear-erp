class SewingEntity {
  const SewingEntity({
    this.id,
    required this.sl,
    required this.voucherNo,
    required this.sewingDate,
    required this.poTagNo,
    required this.quantity,
    required this.entryPerson,
    this.remarks = '',
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final int sl;
  final String voucherNo;
  final DateTime sewingDate;
  final String poTagNo;
  final int quantity;
  final String entryPerson;
  final String remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class POEntity {
  const POEntity({this.id, required this.sl, required this.poDate, required this.tagNo, required this.company, required this.project, required this.brand, required this.poNo, required this.article, required this.color, required this.poQuantity, required this.unitPrice, required this.entryPerson});
  final String? id; final int sl; final DateTime poDate; final String tagNo; final String company; final String project; final String brand; final String poNo; final String article; final String color; final int poQuantity; final double unitPrice; final String entryPerson;
  double get poValue => poQuantity * unitPrice;
}

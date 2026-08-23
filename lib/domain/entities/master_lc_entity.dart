class MasterLCEntity {
  const MasterLCEntity({this.id, required this.sl, required this.masterLcDate, required this.tagNo, required this.project, required this.company, this.scNo = '', this.lcNo = '', this.ttNo = '', required this.masterLcQuantity, required this.masterLcValue});
  final String? id; final int sl; final DateTime masterLcDate; final String tagNo; final String project; final String company; final String scNo; final String lcNo; final String ttNo; final int masterLcQuantity; final double masterLcValue;
}

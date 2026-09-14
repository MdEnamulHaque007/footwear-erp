class MasterLCEntity {
  const MasterLCEntity({this.id, required this.sl, required this.masterLcDate, required this.tagNo, required this.project, required this.company, this.scNo = '', this.lcNo = '', this.ttNo = '', required this.masterLcQuantity, required this.masterLcValue});
  final String? id; final int sl; final DateTime masterLcDate; final String tagNo; final String project; final String company; final String scNo; final String lcNo; final String ttNo; final int masterLcQuantity; final double masterLcValue;

  /// Returns a copy with the provided fields replaced.
  ///
  /// Used by [CreateMasterLCUseCase] to normalise the Sl. to the "unassigned"
  /// sentinel before the repository allocates the real sequence number (SRS
  /// Rule 1: the Sl. is auto-generated, never caller-supplied).
  MasterLCEntity copyWith({
    String? id,
    int? sl,
    DateTime? masterLcDate,
    String? tagNo,
    String? project,
    String? company,
    String? scNo,
    String? lcNo,
    String? ttNo,
    int? masterLcQuantity,
    double? masterLcValue,
  }) => MasterLCEntity(
    id: id ?? this.id,
    sl: sl ?? this.sl,
    masterLcDate: masterLcDate ?? this.masterLcDate,
    tagNo: tagNo ?? this.tagNo,
    project: project ?? this.project,
    company: company ?? this.company,
    scNo: scNo ?? this.scNo,
    lcNo: lcNo ?? this.lcNo,
    ttNo: ttNo ?? this.ttNo,
    masterLcQuantity: masterLcQuantity ?? this.masterLcQuantity,
    masterLcValue: masterLcValue ?? this.masterLcValue,
  );
}

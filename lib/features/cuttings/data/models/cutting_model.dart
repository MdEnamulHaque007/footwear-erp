import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';

part 'cutting_model.freezed.dart';
part 'cutting_model.g.dart';

@freezed
class Cutting with _$Cutting {
  const factory Cutting({
    required String voucherNo,
    required DateTime cuttingDate,
    @Default('') String factoryName,
    required String poNo,
    required String article,
    required String color,
  }) = _Cutting;

  factory Cutting.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Cutting.fromJson(data);
  }

  factory Cutting.fromJson(Map<String, dynamic> json) =>
      _$CuttingFromJson(json);

  Map<String, dynamic> toFirestore() => {
        ..._$CuttingToJson(this),
        'cuttingDate': Timestamp.fromDate(cuttingDate),
        'factoryName': factoryName.trim(),
      };

  String get formattedDate => DateFormat('dd-MMM-yyyy').format(cuttingDate);
}

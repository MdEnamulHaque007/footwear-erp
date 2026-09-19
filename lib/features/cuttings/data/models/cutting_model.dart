import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cutting_model.freezed.dart';
part 'cutting_model.g.dart';

@freezed
class Cutting with _$Cutting {
  const factory Cutting({
    required String voucherNo,
  }) = _Cutting;

  factory Cutting.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Cutting.fromJson(data);
  }

  factory Cutting.fromJson(Map<String, dynamic> json) =>
      _$CuttingFromJson(json);

  Map<String, dynamic> toFirestore() => _$CuttingToJson(this);
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';

part 'cutting_model.freezed.dart';
part 'cutting_model.g.dart';

@freezed
class Cutting with _$Cutting {
  @Assert('cuttingQuantity > 0', 'cuttingQuantity must be greater than 0')
  const factory Cutting({
    required String voucherNo,
    required DateTime cuttingDate,
    @Default('') String factoryName,
    required String poNo,
    required String article,
    required String color,
    required int cuttingQuantity,
    String? entryPerson,
    @JsonKey(includeFromJson: true, includeToJson: true)
    @Default('')
    /// Auto-fetched from purchase_orders.tagNo
    String tagNo,
    @Default('')
    /// Auto-fetched from purchase_orders.
    String company,
    @Default('')
    /// Auto-fetched from purchase_orders.
    String project,
    @Default(0)
    /// From PO lineItems[article+color].poQuantity
    int poQuantity,
    @Default('manual') String source,
    @Default('synced') String syncStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Cutting;

  factory Cutting.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(
      doc.data() ?? <String, dynamic>{},
    );

    for (final key in ['cuttingDate', 'createdAt', 'updatedAt']) {
      final value = data[key];
      if (value is Timestamp) {
        data[key] = value.toDate();
      }
    }

    final cuttingDate =
        data['cuttingDate'] is DateTime ? data['cuttingDate'] as DateTime : DateTime.now();
    final createdAt =
        data['createdAt'] is DateTime ? data['createdAt'] as DateTime : cuttingDate;
    final updatedAt =
        data['updatedAt'] is DateTime ? data['updatedAt'] as DateTime : createdAt;

    data['cuttingDate'] = cuttingDate;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;

    return Cutting.fromJson(data);
  }

  factory Cutting.fromJson(Map<String, dynamic> json) =>
      _$CuttingFromJson(json);

  Map<String, dynamic> toFirestore() => {
        ..._$CuttingToJson(this),
        'cuttingDate': Timestamp.fromDate(cuttingDate),
        'factoryName': factoryName.trim(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.now(),
      };

  String get formattedDate => DateFormat('dd-MMM-yyyy').format(cuttingDate);
}

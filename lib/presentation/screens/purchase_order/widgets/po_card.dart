/// ============================================================================
/// ফাইল: lib/presentation/screens/purchase_order/widgets/po_card.dart
/// স্তর: Presentation Screen | মডিউল: Purchase Order
/// উদ্দেশ্য: Purchase Order মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: POCard
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import '../../../../domain/entities/po_entity.dart';

class POCard extends StatelessWidget {
  const POCard({super.key, required this.item});
  final POEntity item;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(item.poNo),
      subtitle: Text('${item.tagNo} | ${item.article}'),
      trailing: Text(item.poValue.toStringAsFixed(2)),
    ),
  );
}

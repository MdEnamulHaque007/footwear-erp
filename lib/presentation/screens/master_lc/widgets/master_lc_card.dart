/// ============================================================================
/// ফাইল: lib/presentation/screens/master_lc/widgets/master_lc_card.dart
/// স্তর: Presentation Screen | মডিউল: Master LC
/// উদ্দেশ্য: Master LC মডিউলের user interface, input, filter ও user interaction উপস্থাপন করে।
/// প্রধান অংশ: MasterLCCard
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter/material.dart';
import '../../../../domain/entities/master_lc_entity.dart';

class MasterLCCard extends StatelessWidget {
  const MasterLCCard({super.key, required this.item});
  final MasterLCEntity item;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(item.tagNo),
      subtitle: Text('${item.company} | ${item.project}'),
      trailing: Text('${item.masterLcQuantity}'),
    ),
  );
}

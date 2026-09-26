/// ============================================================================
/// ফাইল: lib/presentation/blocs/purchase_order/po_event.dart
/// স্তর: Presentation BLoC | মডিউল: Purchase Order
/// উদ্দেশ্য: Purchase Order screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: POEvent, LoadPOList, LoadMorePOList, SearchPO, ClearSearch, RefreshPOList, LoadPODetail, LoadPOByTag, POUpdated, CreatePO
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../../domain/entities/po_entity.dart';

sealed class POEvent {}

class LoadPOList extends POEvent {}

class LoadMorePOList extends POEvent {}
class SearchPO extends POEvent {
  SearchPO(this.query);
  final String query;
}
class ClearSearch extends POEvent {}
class RefreshPOList extends POEvent {}
class LoadPODetail extends POEvent {
  LoadPODetail(this.id, {this.initialItem});
  final String id;
  final POEntity? initialItem;
}

class LoadPOByTag extends POEvent {
  LoadPOByTag(this.tag);
  final String tag;
}

class POUpdated extends POEvent {
  POUpdated(this.items);
  final List<POEntity> items;
}

class CreatePO extends POEvent {
  CreatePO(this.item);
  final POEntity item;
}

class UpdatePO extends POEvent {
  UpdatePO(this.item);
  final POEntity item;
}

class DeletePO extends POEvent {
  DeletePO(this.id);
  final String id;
}

/// ============================================================================
/// ফাইল: lib/presentation/blocs/purchase_order/po_state.dart
/// স্তর: Presentation BLoC | মডিউল: Purchase Order
/// উদ্দেশ্য: Purchase Order screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: POState, POInitial, POLoading, POLoaded, POError, POSuccess, POSearching, POSearchLoaded, PORefreshing, POEmpty
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../../domain/entities/po_entity.dart';
import '../../../domain/entities/master_lc_entity.dart';

sealed class POState {}

class POInitial extends POState {}

class POLoading extends POState {}

class POLoaded extends POState {
  POLoaded(this.items);
  final List<POEntity> items;
}

class POError extends POState {
  POError(this.message);
  final String message;
}

class POSuccess extends POState {
  POSuccess(this.message);
  final String message;
}
class POSearching extends POState {}
class POSearchLoaded extends POState {
  POSearchLoaded(this.items, this.query);
  final List<POEntity> items;
  final String query;
}
class PORefreshing extends POState {}
class POEmpty extends POState {}
class PODetailLoading extends POState {}
class PODetailLoaded extends POState {
  PODetailLoaded(
    this.item,
    this.master, {
    this.totalTagQuantity,
    this.totalTagValue,
  });
  final POEntity item;
  final MasterLCEntity master;
  final int? totalTagQuantity;
  final double? totalTagValue;
}
class PODetailError extends POState {
  PODetailError(this.message);
  final String message;
}

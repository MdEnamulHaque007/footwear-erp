/// ============================================================================
/// ফাইল: lib/presentation/blocs/master_lc/master_lc_state.dart
/// স্তর: Presentation BLoC | মডিউল: Master LC
/// উদ্দেশ্য: Master LC screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: MasterLCState, MasterLCInitial, MasterLCLoading, MasterLCLoaded, MasterLCLoadingMore, MasterLCError, MasterLCSuccess, MasterLCDeleteSuccess, MasterLCUpdateSuccess, MasterLCDetailLoading
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../../domain/entities/master_lc_entity.dart';
import '../../../domain/entities/po_entity.dart';

sealed class MasterLCState {}

class MasterLCInitial extends MasterLCState {}

class MasterLCLoading extends MasterLCState {}

class MasterLCLoaded extends MasterLCState {
  MasterLCLoaded(this.items, {this.hasMore = false, this.currentPage = 0});
  final List<MasterLCEntity> items;

  /// True when another page is available, which drives the load-more trigger.
  final bool hasMore;
  final int currentPage;
}

/// A page fetch is in flight while the current page stays on screen.
class MasterLCLoadingMore extends MasterLCState {
  MasterLCLoadingMore(this.items, {this.currentPage = 0});
  final List<MasterLCEntity> items;
  final int currentPage;
}

class MasterLCError extends MasterLCState {
  MasterLCError(this.message);
  final String message;
}

class MasterLCSuccess extends MasterLCState {
  MasterLCSuccess(this.message);
  final String message;
}

class MasterLCDeleteSuccess extends MasterLCSuccess {
  MasterLCDeleteSuccess(super.message);
}

class MasterLCUpdateSuccess extends MasterLCSuccess {
  MasterLCUpdateSuccess(super.message);
}

class MasterLCDetailLoading extends MasterLCState {}

class MasterLCDetailLoaded extends MasterLCState {
  MasterLCDetailLoaded({
    required this.masterLC,
    required this.purchaseOrders,
    required this.totalPOQuantity,
    required this.totalPOValue,
  });
  final MasterLCEntity masterLC;
  final List<POEntity> purchaseOrders;
  final int totalPOQuantity;
  final double totalPOValue;
  int get pendingQuantity => masterLC.masterLcQuantity - totalPOQuantity;
  double get pendingValue => masterLC.masterLcValue - totalPOValue;
}

class MasterLCDetailError extends MasterLCState {
  MasterLCDetailError(this.message);
  final String message;
}

/// Predefined Project / Company options for the Master LC form dropdowns.
class PredefinedListsLoaded extends MasterLCState {
  PredefinedListsLoaded({required this.projects, required this.companies});
  final List<String> projects;
  final List<String> companies;
}

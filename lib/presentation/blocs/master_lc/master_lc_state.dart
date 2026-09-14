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

import '../../../domain/entities/master_lc_entity.dart';
import '../../../domain/entities/po_entity.dart';

sealed class MasterLCState {}

class MasterLCInitial extends MasterLCState {}

class MasterLCLoading extends MasterLCState {}

class MasterLCLoaded extends MasterLCState {
  MasterLCLoaded(this.items);
  final List<MasterLCEntity> items;
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

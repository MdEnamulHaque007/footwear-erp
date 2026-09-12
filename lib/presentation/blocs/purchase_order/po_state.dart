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

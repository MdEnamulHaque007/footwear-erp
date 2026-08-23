import '../../../domain/entities/po_entity.dart';

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

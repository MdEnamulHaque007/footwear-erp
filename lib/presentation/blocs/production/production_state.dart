import '../../../domain/entities/production_entity.dart';

sealed class ProductionState {}

class ProductionInitial extends ProductionState {}

class ProductionLoading extends ProductionState {}

class ProductionLoaded extends ProductionState {
  ProductionLoaded(this.items);
  final List<ProductionEntity> items;
}

class ProductionError extends ProductionState {
  ProductionError(this.message);
  final String message;
}

class ProductionSuccess extends ProductionState {
  ProductionSuccess(this.message);
  final String message;
}

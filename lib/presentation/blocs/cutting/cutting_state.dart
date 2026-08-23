import '../../../domain/entities/cutting_entity.dart';

sealed class CuttingState {}

class CuttingInitial extends CuttingState {}

class CuttingLoading extends CuttingState {}

class CuttingLoaded extends CuttingState {
  CuttingLoaded(this.items);
  final List<CuttingEntity> items;
}

class CuttingError extends CuttingState {
  CuttingError(this.message);
  final String message;
}

class CuttingSuccess extends CuttingState {
  CuttingSuccess(this.message);
  final String message;
}

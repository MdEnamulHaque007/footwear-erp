import '../../../domain/entities/sewing_entity.dart';

sealed class SewingState {}

class SewingInitial extends SewingState {}

class SewingLoading extends SewingState {}

class SewingLoaded extends SewingState {
  SewingLoaded(this.items);
  final List<SewingEntity> items;
}

class SewingError extends SewingState {
  SewingError(this.message);
  final String message;
}

class SewingSuccess extends SewingState {
  SewingSuccess(this.message);
  final String message;
}

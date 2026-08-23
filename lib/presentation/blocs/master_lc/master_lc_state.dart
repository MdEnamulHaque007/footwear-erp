import '../../../domain/entities/master_lc_entity.dart';

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

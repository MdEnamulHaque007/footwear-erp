import '../../../domain/entities/master_lc_entity.dart';

sealed class MasterLCEvent {}

class LoadMasterLCList extends MasterLCEvent {}
class LoadMoreMasterLC extends MasterLCEvent {}

class MasterLCUpdated extends MasterLCEvent {
  MasterLCUpdated(this.items);
  final List<MasterLCEntity> items;
}

class CreateMasterLC extends MasterLCEvent {
  CreateMasterLC(this.item);
  final MasterLCEntity item;
}

class UpdateMasterLC extends MasterLCEvent {
  UpdateMasterLC(this.item);
  final MasterLCEntity item;
}

class DeleteMasterLC extends MasterLCEvent {
  DeleteMasterLC(this.id);
  final String id;
}

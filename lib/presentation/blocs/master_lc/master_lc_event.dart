import '../../../domain/entities/master_lc_entity.dart';

sealed class MasterLCEvent {}

class LoadMasterLCList extends MasterLCEvent {
  LoadMasterLCList({this.limit = 20});
  final int limit;
}

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

class LoadMasterLCDetail extends MasterLCEvent {
  LoadMasterLCDetail(this.id, {this.initialItem});
  final String id;
  final MasterLCEntity? initialItem;
}

/// Loads the predefined Project / Company lists for the form dropdowns.
class LoadPredefinedLists extends MasterLCEvent {}

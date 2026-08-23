import '../../../domain/entities/po_entity.dart';

sealed class POEvent {}

class LoadPOList extends POEvent {}

class LoadMorePOList extends POEvent {}

class LoadPOByTag extends POEvent {
  LoadPOByTag(this.tag);
  final String tag;
}

class POUpdated extends POEvent {
  POUpdated(this.items);
  final List<POEntity> items;
}

class CreatePO extends POEvent {
  CreatePO(this.item);
  final POEntity item;
}

class UpdatePO extends POEvent {
  UpdatePO(this.item);
  final POEntity item;
}

class DeletePO extends POEvent {
  DeletePO(this.id);
  final String id;
}

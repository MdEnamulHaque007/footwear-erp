import '../../../domain/entities/po_entity.dart';

sealed class POEvent {}

class LoadPOList extends POEvent {}

class LoadMorePOList extends POEvent {}
class SearchPO extends POEvent {
  SearchPO(this.query);
  final String query;
}
class ClearSearch extends POEvent {}
class RefreshPOList extends POEvent {}
class LoadPODetail extends POEvent {
  LoadPODetail(this.id, {this.initialItem});
  final String id;
  final POEntity? initialItem;
}

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

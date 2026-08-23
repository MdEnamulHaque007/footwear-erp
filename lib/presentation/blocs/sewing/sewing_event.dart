import '../../../domain/entities/sewing_entity.dart';

sealed class SewingEvent {}

class LoadSewingList extends SewingEvent {}

class LoadMoreSewingList extends SewingEvent {}

class CreateSewing extends SewingEvent {
  CreateSewing(this.item);
  final SewingEntity item;
}

class UpdateSewing extends SewingEvent {
  UpdateSewing(this.item);
  final SewingEntity item;
}

class DeleteSewing extends SewingEvent {
  DeleteSewing(this.id);
  final String id;
}

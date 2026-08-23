import '../../../domain/entities/cutting_entity.dart';

sealed class CuttingEvent {}

class LoadCuttingList extends CuttingEvent {}

class LoadMoreCuttingList extends CuttingEvent {}

class CreateCutting extends CuttingEvent {
  CreateCutting(this.item);
  final CuttingEntity item;
}

class UpdateCutting extends CuttingEvent {
  UpdateCutting(this.item);
  final CuttingEntity item;
}

class DeleteCutting extends CuttingEvent {
  DeleteCutting(this.id);
  final String id;
}

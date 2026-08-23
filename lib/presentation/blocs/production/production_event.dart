import '../../../domain/entities/production_entity.dart';

sealed class ProductionEvent {}

class LoadProductionList extends ProductionEvent {}

class LoadMoreProductionList extends ProductionEvent {}

class CreateProduction extends ProductionEvent {
  CreateProduction(this.item);
  final ProductionEntity item;
}

class UpdateProduction extends ProductionEvent {
  UpdateProduction(this.item);
  final ProductionEntity item;
}

class DeleteProduction extends ProductionEvent {
  DeleteProduction(this.id);
  final String id;
}

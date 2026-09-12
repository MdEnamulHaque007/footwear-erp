import '../../../domain/entities/cutting_entity.dart';

sealed class CuttingEvent {}

class LoadCuttingList extends CuttingEvent {}

class LoadMoreCuttingList extends CuttingEvent {}

class SearchCutting extends CuttingEvent {
  SearchCutting(this.query);
  final String query;
}

class ClearSearchCutting extends CuttingEvent {}

class RefreshCutting extends CuttingEvent {}

class LoadCuttingDetail extends CuttingEvent {
  LoadCuttingDetail(this.id, {this.initialItem});
  final String id;
  final CuttingEntity? initialItem;
}

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

class LoadPONoList extends CuttingEvent {}

class SelectPO extends CuttingEvent {
  SelectPO(this.poNo);
  final String poNo;
}

class LoadPOArticles extends CuttingEvent {
  LoadPOArticles(this.poNo);
  final String poNo;
}

class LoadArticleColors extends CuttingEvent {
  LoadArticleColors(this.poNo, this.article);
  final String poNo;
  final String article;
}

class LoadPOQuantity extends CuttingEvent {
  LoadPOQuantity(this.poNo, this.article, this.color);
  final String poNo;
  final String article;
  final String color;
}

class ValidateCutting extends CuttingEvent {
  ValidateCutting(
    this.poNo,
    this.article,
    this.color,
    this.poQuantity,
    this.quantity,
  );
  final String poNo;
  final String article;
  final String color;
  final int poQuantity;
  final int quantity;
}

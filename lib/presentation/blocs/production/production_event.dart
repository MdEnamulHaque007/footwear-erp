import '../../../domain/entities/production_entity.dart';

sealed class ProductionEvent {}

class LoadProductionList extends ProductionEvent {}

class LoadMoreProductionList extends ProductionEvent {}

class SearchProduction extends ProductionEvent {
  SearchProduction(this.query);
  final String query;
}

class ClearSearchProduction extends ProductionEvent {}

class RefreshProduction extends ProductionEvent {}

class LoadProductionDetail extends ProductionEvent {
  LoadProductionDetail(this.id, {this.initialItem});
  final String id;
  final ProductionEntity? initialItem;
}

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

/// Loads the PO dropdown (PO No + full PO documents).
class LoadPONoList extends ProductionEvent {}

/// Selects a PO and auto-fills Tag No / Company / Project + Article list.
class SelectPO extends ProductionEvent {
  SelectPO(this.poNo);
  final String poNo;
}

/// Article list for the selected PO (used on first load / edit).
class LoadPOArticles extends ProductionEvent {
  LoadPOArticles(this.poNo);
  final String poNo;
}

/// Cascading: Article -> Color list (sourced from the Sewing entries).
class LoadArticleColors extends ProductionEvent {
  LoadArticleColors(this.poNo, this.article);
  final String poNo;
  final String article;
}

/// Unit price of the selected PO line (drives the auto Production Value).
class LoadUnitPrice extends ProductionEvent {
  LoadUnitPrice(this.poNo, this.article, this.color);
  final String poNo;
  final String article;
  final String color;
}

/// Cumulative Sewing (date-filtered) / Production / Available for a PO line.
class LoadAvailableQuantity extends ProductionEvent {
  LoadAvailableQuantity({
    required this.poTagNo,
    required this.poNo,
    required this.article,
    required this.color,
    required this.productionDate,
    this.excludeId,
  });
  final String poTagNo;
  final String poNo;
  final String article;
  final String color;
  final DateTime productionDate;
  final String? excludeId;
}

/// Real-time validation of the quantity being typed.
class ValidateProduction extends ProductionEvent {
  ValidateProduction({
    required this.poTagNo,
    required this.poNo,
    required this.article,
    required this.color,
    required this.quantity,
    required this.productionDate,
    this.excludeId,
  });
  final String poTagNo;
  final String poNo;
  final String article;
  final String color;
  final int quantity;
  final DateTime productionDate;
  final String? excludeId;
}

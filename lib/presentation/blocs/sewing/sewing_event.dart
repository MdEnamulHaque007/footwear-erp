import '../../../domain/entities/sewing_entity.dart';

sealed class SewingEvent {}

class LoadSewingList extends SewingEvent {}

class LoadMoreSewingList extends SewingEvent {}

class SearchSewing extends SewingEvent {
  SearchSewing(this.query);
  final String query;
}

class ClearSearchSewing extends SewingEvent {}

class RefreshSewing extends SewingEvent {}

class LoadSewingDetail extends SewingEvent {
  LoadSewingDetail(this.id, {this.initialItem});
  final String id;
  final SewingEntity? initialItem;
}

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

/// Loads the PO dropdown (PO No + full PO documents).
class LoadPONoList extends SewingEvent {}

/// Selects a PO and auto-fills Tag No / Company / Project + Article list.
class SelectPO extends SewingEvent {
  SelectPO(this.poNo);
  final String poNo;
}

class LoadPOArticles extends SewingEvent {
  LoadPOArticles(this.poNo);
  final String poNo;
}

/// Cascading: Article → Color list.
class LoadArticleColors extends SewingEvent {
  LoadArticleColors(this.poNo, this.article);
  final String poNo;
  final String article;
}

/// Cumulative Cutting (date-filtered) / Sewing / Available for a PO line.
class LoadAvailableQuantity extends SewingEvent {
  LoadAvailableQuantity({
    required this.poNo,
    required this.article,
    required this.color,
    required this.sewingDate,
    this.excludeId,
  });
  final String poNo;
  final String article;
  final String color;
  final DateTime sewingDate;
  final String? excludeId;
}

/// Real-time validation of the quantity being typed.
class ValidateSewing extends SewingEvent {
  ValidateSewing({
    required this.poNo,
    required this.article,
    required this.color,
    required this.quantity,
    required this.sewingDate,
    this.excludeId,
  });
  final String poNo;
  final String article;
  final String color;
  final int quantity;
  final DateTime sewingDate;
  final String? excludeId;
}


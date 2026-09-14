import '../../../domain/entities/export_entity.dart';

sealed class ExportEvent {}

class LoadExportList extends ExportEvent {}

class LoadMoreExportList extends ExportEvent {}

class SearchExport extends ExportEvent {
  SearchExport(this.query);
  final String query;
}

class ClearSearchExport extends ExportEvent {}

class RefreshExport extends ExportEvent {}

class LoadExportDetail extends ExportEvent {
  LoadExportDetail(this.id, {this.initialItem});
  final String id;
  final ExportEntity? initialItem;
}

class CreateExport extends ExportEvent {
  CreateExport(this.item);
  final ExportEntity item;
}

class UpdateExport extends ExportEvent {
  UpdateExport(this.item);
  final ExportEntity item;
}

class DeleteExport extends ExportEvent {
  DeleteExport(this.id);
  final String id;
}

/// Loads the PO dropdown (Issue-filtered PO No list).
class LoadPONoList extends ExportEvent {}

/// Selects a PO and resolves its Tag No / Company / Project header.
class SelectPO extends ExportEvent {
  SelectPO(this.poNo);
  final String poNo;
}

/// Cascading: Article + Color list from the Issue entries.
class LoadArticleColors extends ExportEvent {
  LoadArticleColors(this.poNo, this.article);
  final String poNo;
  final String article;
}

/// Issue-filtered article list for the selected PO.
class LoadPOArticles extends ExportEvent {
  LoadPOArticles(this.poNo);
  final String poNo;
}

/// Unit price of the selected PO line (drives the auto Export Value).
class LoadUnitPrice extends ExportEvent {
  LoadUnitPrice(this.poNo, this.article, this.color);
  final String poNo;
  final String article;
  final String color;
}

/// Cumulative Issue (date-filtered) / Export / Available for a PO line.
class LoadAvailableQuantity extends ExportEvent {
  LoadAvailableQuantity({
    required this.poTagNo,
    required this.poNo,
    required this.article,
    required this.color,
    required this.exportDate,
    this.excludeId,
  });
  final String poTagNo;
  final String poNo;
  final String article;
  final String color;
  final DateTime exportDate;
  final String? excludeId;
}

/// Real-time validation of the quantity being typed.
class ValidateExport extends ExportEvent {
  ValidateExport({
    required this.poTagNo,
    required this.poNo,
    required this.article,
    required this.color,
    required this.quantity,
    required this.exportDate,
    this.excludeId,
  });
  final String poTagNo;
  final String poNo;
  final String article;
  final String color;
  final int quantity;
  final DateTime exportDate;
  final String? excludeId;
}

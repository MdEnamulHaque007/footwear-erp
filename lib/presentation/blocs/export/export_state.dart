import '../../../domain/entities/export_entity.dart';
import '../../../domain/entities/po_entity.dart';

sealed class ExportState {}

class ExportInitial extends ExportState {}

class ExportLoading extends ExportState {}

class ExportLoaded extends ExportState {
  ExportLoaded(this.items, {this.hasMore = false, this.currentPage = 0});
  final List<ExportEntity> items;
  final bool hasMore;
  final int currentPage;
}

class ExportSearchLoaded extends ExportLoaded {
  ExportSearchLoaded(super.items);
}

class ExportDetailLoaded extends ExportState {
  ExportDetailLoaded({
    required this.item,
    required this.related,
    required this.issueQuantity,
    required this.totalExportQuantity,
    required this.availableQuantity,
  });
  final ExportEntity item;
  final List<ExportEntity> related;
  final int issueQuantity;
  final int totalExportQuantity;
  final int availableQuantity;
}

class ExportError extends ExportState {
  ExportError(this.message);
  final String message;
}

class ExportSuccess extends ExportState {
  ExportSuccess(this.message);
  final String message;
}

class PONoListLoaded extends ExportState {
  PONoListLoaded(this.poNoList, this.poList);
  final List<String> poNoList;
  final List<POEntity> poList;
}

class POSelected extends ExportState {
  POSelected(this.poNo, this.tagNo, this.company, this.project, this.articles);
  final String poNo;
  final String tagNo;
  final String company;
  final String project;
  final List<String> articles;
}

class ArticleListLoaded extends ExportState {
  ArticleListLoaded(this.articles);
  final List<String> articles;
}

class ColorListLoaded extends ExportState {
  ColorListLoaded(this.colors);
  final List<String> colors;
}

class UnitPriceLoaded extends ExportState {
  UnitPriceLoaded(this.unitPrice);
  final double unitPrice;
}

class AvailableQuantityLoaded extends ExportState {
  AvailableQuantityLoaded({
    required this.issueQty,
    required this.exportQty,
    required this.availableQty,
  });
  final int issueQty;
  final int exportQty;
  final int availableQty;
}

class ExportValidationError extends ExportState {
  ExportValidationError(this.message);
  final String message;
}

class ExportValidationSuccess extends ExportState {}

import '../../../domain/entities/cutting_entity.dart';
import '../../../domain/entities/po_entity.dart';

sealed class CuttingState {}

class CuttingInitial extends CuttingState {}

class CuttingLoading extends CuttingState {}

class CuttingLoaded extends CuttingState {
  CuttingLoaded(this.items, {this.hasMore = false, this.currentPage = 0});
  final List<CuttingEntity> items;
  final bool hasMore;
  final int currentPage;
}

class CuttingSearchLoaded extends CuttingLoaded {
  CuttingSearchLoaded(super.items);
}

class CuttingDetailLoaded extends CuttingState {
  CuttingDetailLoaded({
    required this.item,
    required this.related,
    required this.totalQuantity,
    required this.availableQuantity,
  });
  final CuttingEntity item;
  final List<CuttingEntity> related;
  final int totalQuantity;
  final int availableQuantity;
}

class CuttingRefreshed extends CuttingState {}

class CuttingError extends CuttingState {
  CuttingError(this.message);
  final String message;
}

class CuttingSuccess extends CuttingState {
  CuttingSuccess(this.message);
  final String message;
}

class PONoListLoaded extends CuttingState {
  PONoListLoaded(this.poNoList, this.poList);
  final List<String> poNoList;
  final List<POEntity> poList;
}

class POSelected extends CuttingState {
  POSelected(this.poNo, this.tagNo, this.company, this.project, this.articles);
  final String poNo;
  final String tagNo;
  final String company;
  final String project;
  final List<String> articles;
}

class ArticleListLoaded extends CuttingState {
  ArticleListLoaded(this.articles);
  final List<String> articles;
}

class ColorListLoaded extends CuttingState {
  ColorListLoaded(this.colors);
  final List<String> colors;
}

class AvailableQuantityLoaded extends CuttingState {
  AvailableQuantityLoaded(this.availableQty, this.poQty);
  final int availableQty;
  final int poQty;
}

class POQuantityLoaded extends AvailableQuantityLoaded {
  POQuantityLoaded(super.availableQty, super.poQty);
}

class CuttingValidationError extends CuttingState {
  CuttingValidationError(this.message);
  final String message;
}

class CuttingValidationSuccess extends CuttingState {}

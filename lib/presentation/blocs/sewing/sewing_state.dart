import '../../../domain/entities/po_entity.dart';
import '../../../domain/entities/sewing_entity.dart';

sealed class SewingState {}

class SewingInitial extends SewingState {}

class SewingLoading extends SewingState {}

class SewingLoaded extends SewingState {
  SewingLoaded(this.items, {this.hasMore = false, this.currentPage = 0});
  final List<SewingEntity> items;
  final bool hasMore;
  final int currentPage;
}

class SewingSearchLoaded extends SewingLoaded {
  SewingSearchLoaded(super.items);
}

class SewingDetailLoaded extends SewingState {
  SewingDetailLoaded({
    required this.item,
    required this.related,
    required this.cuttingQuantity,
    required this.totalSewingQuantity,
    required this.availableQuantity,
  });
  final SewingEntity item;
  final List<SewingEntity> related;
  final int cuttingQuantity;
  final int totalSewingQuantity;
  final int availableQuantity;
}

class SewingError extends SewingState {
  SewingError(this.message);
  final String message;
}

class SewingSuccess extends SewingState {
  SewingSuccess(this.message);
  final String message;
}

class PONoListLoaded extends SewingState {
  PONoListLoaded(this.poNoList, this.poList);
  final List<String> poNoList;
  final List<POEntity> poList;
}

class POSelected extends SewingState {
  POSelected(this.poNo, this.tagNo, this.company, this.project, this.articles);
  final String poNo;
  final String tagNo;
  final String company;
  final String project;
  final List<String> articles;
}

class ArticleListLoaded extends SewingState {
  ArticleListLoaded(this.articles);
  final List<String> articles;
}

class ColorListLoaded extends SewingState {
  ColorListLoaded(this.colors);
  final List<String> colors;
}

class AvailableQuantityLoaded extends SewingState {
  AvailableQuantityLoaded({
    required this.cuttingQty,
    required this.sewingQty,
    required this.availableQty,
  });
  final int cuttingQty;
  final int sewingQty;
  final int availableQty;
}

class SewingValidationError extends SewingState {
  SewingValidationError(this.message);
  final String message;
}

class SewingValidationSuccess extends SewingState {}


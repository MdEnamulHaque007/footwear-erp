/// ============================================================================
/// ফাইল: lib/presentation/blocs/production/production_state.dart
/// স্তর: Presentation BLoC | মডিউল: Production/Lasting
/// উদ্দেশ্য: Production/Lasting screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: ProductionState, ProductionInitial, ProductionLoading, ProductionLoaded, ProductionSearchLoaded, ProductionDetailLoaded, ProductionError, ProductionSuccess, PONoListLoaded, POSelected
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../../domain/entities/po_entity.dart';
import '../../../domain/entities/production_entity.dart';

sealed class ProductionState {}

class ProductionInitial extends ProductionState {}

class ProductionLoading extends ProductionState {}

class ProductionLoaded extends ProductionState {
  ProductionLoaded(this.items, {this.hasMore = false, this.currentPage = 0});
  final List<ProductionEntity> items;
  final bool hasMore;
  final int currentPage;
}

class ProductionSearchLoaded extends ProductionLoaded {
  ProductionSearchLoaded(super.items);
}

class ProductionDetailLoaded extends ProductionState {
  ProductionDetailLoaded({
    required this.item,
    required this.related,
    required this.sewingQuantity,
    required this.totalProductionQuantity,
    required this.availableQuantity,
  });
  final ProductionEntity item;
  final List<ProductionEntity> related;
  final int sewingQuantity;
  final int totalProductionQuantity;
  final int availableQuantity;
}

class ProductionError extends ProductionState {
  ProductionError(this.message);
  final String message;
}

class ProductionSuccess extends ProductionState {
  ProductionSuccess(this.message);
  final String message;
}

class PONoListLoaded extends ProductionState {
  PONoListLoaded(this.poNoList, this.poList);
  final List<String> poNoList;
  final List<POEntity> poList;
}

class POSelected extends ProductionState {
  POSelected(this.poNo, this.tagNo, this.company, this.project, this.articles);
  final String poNo;
  final String tagNo;
  final String company;
  final String project;
  final List<String> articles;
}

class ArticleListLoaded extends ProductionState {
  ArticleListLoaded(this.articles);
  final List<String> articles;
}

class ColorListLoaded extends ProductionState {
  ColorListLoaded(this.colors);
  final List<String> colors;
}

class UnitPriceLoaded extends ProductionState {
  UnitPriceLoaded(this.unitPrice);
  final double unitPrice;
}

class AvailableQuantityLoaded extends ProductionState {
  AvailableQuantityLoaded({
    required this.sewingQty,
    required this.producedQty,
    required this.availableQty,
  });
  final int sewingQty;
  final int producedQty;
  final int availableQty;
}

class ProductionValidationError extends ProductionState {
  ProductionValidationError(this.message);
  final String message;
}

class ProductionValidationSuccess extends ProductionState {}

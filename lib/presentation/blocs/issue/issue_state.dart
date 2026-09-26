/// ============================================================================
/// ফাইল: lib/presentation/blocs/issue/issue_state.dart
/// স্তর: Presentation BLoC | মডিউল: Finished Goods Issue
/// উদ্দেশ্য: Finished Goods Issue screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: IssueState, IssueInitial, IssueLoading, IssueLoaded, IssueSearchLoaded, IssueDetailLoaded, IssueError, IssueSuccess, PONoListLoaded, POSelected
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../../domain/entities/issue_entity.dart';
import '../../../domain/entities/po_entity.dart';

sealed class IssueState {}

class IssueInitial extends IssueState {}

class IssueLoading extends IssueState {}

class IssueLoaded extends IssueState {
  IssueLoaded(this.items, {this.hasMore = false, this.currentPage = 0});
  final List<IssueEntity> items;
  final bool hasMore;
  final int currentPage;
}

class IssueSearchLoaded extends IssueLoaded {
  IssueSearchLoaded(super.items);
}

class IssueDetailLoaded extends IssueState {
  IssueDetailLoaded({
    required this.item,
    required this.related,
    required this.productionQuantity,
    required this.totalIssueQuantity,
    required this.availableQuantity,
  });
  final IssueEntity item;
  final List<IssueEntity> related;
  final int productionQuantity;
  final int totalIssueQuantity;
  final int availableQuantity;
}

class IssueError extends IssueState {
  IssueError(this.message);
  final String message;
}

class IssueSuccess extends IssueState {
  IssueSuccess(this.message);
  final String message;
}

class PONoListLoaded extends IssueState {
  PONoListLoaded(this.poNoList, this.poList);
  final List<String> poNoList;
  final List<POEntity> poList;
}

class POSelected extends IssueState {
  POSelected(this.poNo, this.tagNo, this.company, this.project, this.articles);
  final String poNo;
  final String tagNo;
  final String company;
  final String project;
  final List<String> articles;
}

class ArticleListLoaded extends IssueState {
  ArticleListLoaded(this.articles);
  final List<String> articles;
}

class ColorListLoaded extends IssueState {
  ColorListLoaded(this.colors);
  final List<String> colors;
}

class UnitPriceLoaded extends IssueState {
  UnitPriceLoaded(this.unitPrice);
  final double unitPrice;
}

class AvailableQuantityLoaded extends IssueState {
  AvailableQuantityLoaded({
    required this.productionQty,
    required this.issueQty,
    required this.availableQty,
  });
  final int productionQty;
  final int issueQty;
  final int availableQty;
}

class IssueValidationError extends IssueState {
  IssueValidationError(this.message);
  final String message;
}

class IssueValidationSuccess extends IssueState {}

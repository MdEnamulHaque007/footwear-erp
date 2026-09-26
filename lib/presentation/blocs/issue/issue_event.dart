/// ============================================================================
/// ফাইল: lib/presentation/blocs/issue/issue_event.dart
/// স্তর: Presentation BLoC | মডিউল: Finished Goods Issue
/// উদ্দেশ্য: Finished Goods Issue screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: IssueEvent, LoadIssueList, LoadMoreIssueList, SearchIssue, ClearSearchIssue, RefreshIssue, LoadIssueDetail, CreateIssue, UpdateIssue, DeleteIssue
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../../domain/entities/issue_entity.dart';

sealed class IssueEvent {}

class LoadIssueList extends IssueEvent {}

class LoadMoreIssueList extends IssueEvent {}

class SearchIssue extends IssueEvent {
  SearchIssue(this.query);
  final String query;
}

class ClearSearchIssue extends IssueEvent {}

class RefreshIssue extends IssueEvent {}

class LoadIssueDetail extends IssueEvent {
  LoadIssueDetail(this.id, {this.initialItem});
  final String id;
  final IssueEntity? initialItem;
}

class CreateIssue extends IssueEvent {
  CreateIssue(this.item);
  final IssueEntity item;
}

class UpdateIssue extends IssueEvent {
  UpdateIssue(this.item);
  final IssueEntity item;
}

class DeleteIssue extends IssueEvent {
  DeleteIssue(this.id);
  final String id;
}

/// Loads the PO dropdown (Production-filtered PO No list).
class LoadPONoList extends IssueEvent {}

/// Selects a PO and resolves its Tag No / Company / Project header.
class SelectPO extends IssueEvent {
  SelectPO(this.poNo);
  final String poNo;
}

/// Cascading: Article + Color list from the Production entries.
class LoadArticleColors extends IssueEvent {
  LoadArticleColors(this.poNo, this.article);
  final String poNo;
  final String article;
}

/// Production-filtered article list for the selected PO.
class LoadPOArticles extends IssueEvent {
  LoadPOArticles(this.poNo);
  final String poNo;
}

/// Unit price of the selected PO line (drives the auto Issue Value).
class LoadUnitPrice extends IssueEvent {
  LoadUnitPrice(this.poNo, this.article, this.color);
  final String poNo;
  final String article;
  final String color;
}

/// Cumulative Production (date-filtered) / Issue / Available for a PO line.
class LoadAvailableQuantity extends IssueEvent {
  LoadAvailableQuantity({
    required this.poTagNo,
    required this.poNo,
    required this.article,
    required this.color,
    required this.issueDate,
    this.excludeId,
  });
  final String poTagNo;
  final String poNo;
  final String article;
  final String color;
  final DateTime issueDate;
  final String? excludeId;
}

/// Real-time validation of the quantity being typed.
class ValidateIssue extends IssueEvent {
  ValidateIssue({
    required this.poTagNo,
    required this.poNo,
    required this.article,
    required this.color,
    required this.quantity,
    required this.issueDate,
    this.excludeId,
  });
  final String poTagNo;
  final String poNo;
  final String article;
  final String color;
  final int quantity;
  final DateTime issueDate;
  final String? excludeId;
}

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

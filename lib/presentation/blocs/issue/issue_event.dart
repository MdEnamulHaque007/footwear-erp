import '../../../domain/entities/issue_entity.dart';

sealed class IssueEvent {}

class LoadIssueList extends IssueEvent {}

class LoadMoreIssueList extends IssueEvent {}

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

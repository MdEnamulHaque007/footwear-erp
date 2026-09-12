import '../../../domain/entities/issue_entity.dart';

sealed class IssueState {}

class IssueInitial extends IssueState {}

class IssueLoading extends IssueState {}

class IssueLoaded extends IssueState {
  IssueLoaded(this.items);
  final List<IssueEntity> items;
}

class IssueError extends IssueState {
  IssueError(this.message);
  final String message;
}

class IssueSuccess extends IssueState {
  IssueSuccess(this.message);
  final String message;
}

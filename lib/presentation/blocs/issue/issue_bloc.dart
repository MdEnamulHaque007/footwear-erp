import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/issue_entity.dart';
import '../../../domain/usecases/issue/create_issue_usecase.dart';
import '../../../domain/usecases/issue/delete_issue_usecase.dart';
import '../../../domain/usecases/issue/get_issue_list_usecase.dart';
import '../../../domain/usecases/issue/update_issue_usecase.dart';
import 'issue_event.dart';
import 'issue_state.dart';

class IssueBloc extends Bloc<IssueEvent, IssueState> {
  IssueBloc({
    required this.getList,
    required this.create,
    required this.update,
    required this.delete,
  }) : super(IssueInitial()) {
    on<LoadIssueList>((event, emit) async {
      _currentPage = 0;
      _hasMore = true;
      emit(IssueLoading());
      final result = await getList(page: _currentPage, limit: 20);
      if (emit.isDone) return;
      result.fold((error) => emit(IssueError(error)), (items) {
        _items = items;
        _hasMore = items.length == 20;
        emit(IssueLoaded(_items));
      });
    });

    on<LoadMoreIssueList>((event, emit) async {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
      final pageToLoad = _currentPage + 1;
      try {
        final result = await getList(page: pageToLoad, limit: 20);
        if (emit.isDone) return;
        result.fold((error) => emit(IssueError(error)), (items) {
          _currentPage = pageToLoad;
          _items.addAll(items);
          _hasMore = items.length == 20;
          emit(IssueLoaded(List.from(_items)));
        });
      } finally {
        _isLoadingMore = false;
      }
    });

    on<CreateIssue>((event, emit) async {
      emit(IssueLoading());
      final result = await create(event.item);
      if (emit.isDone) return;
      result.fold((error) => emit(IssueError(error)), (_) {
        emit(IssueSuccess('Issue record created'));
        add(LoadIssueList());
      });
    });

    on<UpdateIssue>((event, emit) async {
      emit(IssueLoading());
      final result = await update(event.item);
      if (emit.isDone) return;
      result.fold((error) => emit(IssueError(error)), (_) {
        emit(IssueSuccess('Issue record updated'));
        add(LoadIssueList());
      });
    });

    on<DeleteIssue>((event, emit) async {
      emit(IssueLoading());
      final result = await delete(event.id);
      if (emit.isDone) return;
      result.fold((error) => emit(IssueError(error)), (_) {
        emit(IssueSuccess('Issue record deleted'));
        add(LoadIssueList());
      });
    });
  }

  final GetIssueListUseCase getList;
  final CreateIssueUseCase create;
  final UpdateIssueUseCase update;
  final DeleteIssueUseCase delete;

  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<IssueEntity> _items = [];
}

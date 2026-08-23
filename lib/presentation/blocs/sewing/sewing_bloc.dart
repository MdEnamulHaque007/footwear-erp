import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/sewing_entity.dart';
import '../../../domain/usecases/sewing/create_sewing_usecase.dart';
import '../../../domain/usecases/sewing/delete_sewing_usecase.dart';
import '../../../domain/usecases/sewing/get_sewing_list_usecase.dart';
import '../../../domain/usecases/sewing/update_sewing_usecase.dart';
import 'sewing_event.dart';
import 'sewing_state.dart';

class SewingBloc extends Bloc<SewingEvent, SewingState> {
  SewingBloc({
    required this.getList,
    required this.create,
    required this.update,
    required this.delete,
  }) : super(SewingInitial()) {
    on<LoadSewingList>((event, emit) async {
      _currentPage = 0;
      _hasMore = true;
      emit(SewingLoading());
      final result = await getList(page: _currentPage, limit: 20);
      result.fold((error) => emit(SewingError(error)), (items) {
        _items = items;
        _hasMore = items.length == 20;
        emit(SewingLoaded(_items));
      });
    });

    on<LoadMoreSewingList>((event, emit) async {
      if (!_hasMore) return;
      _currentPage++;
      final result = await getList(page: _currentPage, limit: 20);
      result.fold((error) => emit(SewingError(error)), (items) {
        _items.addAll(items);
        _hasMore = items.length == 20;
        emit(SewingLoaded(List.from(_items)));
      });
    });

    on<CreateSewing>((event, emit) async {
      emit(SewingLoading());
      final result = await create(event.item);
      result.fold((error) => emit(SewingError(error)), (_) {
        emit(SewingSuccess('Sewing record created'));
        add(LoadSewingList());
      });
    });

    on<UpdateSewing>((event, emit) async {
      emit(SewingLoading());
      final result = await update(event.item);
      result.fold((error) => emit(SewingError(error)), (_) {
        emit(SewingSuccess('Sewing record updated'));
        add(LoadSewingList());
      });
    });

    on<DeleteSewing>((event, emit) async {
      emit(SewingLoading());
      final result = await delete(event.id);
      result.fold((error) => emit(SewingError(error)), (_) {
        emit(SewingSuccess('Sewing record deleted'));
        add(LoadSewingList());
      });
    });
  }

  final GetSewingListUseCase getList;
  final CreateSewingUseCase create;
  final UpdateSewingUseCase update;
  final DeleteSewingUseCase delete;

  int _currentPage = 0;
  bool _hasMore = true;
  List<SewingEntity> _items = [];
}

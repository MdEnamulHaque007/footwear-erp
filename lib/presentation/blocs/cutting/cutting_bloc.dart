import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/cutting_entity.dart';
import '../../../domain/usecases/cutting/create_cutting_usecase.dart';
import '../../../domain/usecases/cutting/delete_cutting_usecase.dart';
import '../../../domain/usecases/cutting/get_cutting_list_usecase.dart';
import '../../../domain/usecases/cutting/update_cutting_usecase.dart';
import 'cutting_event.dart';
import 'cutting_state.dart';

class CuttingBloc extends Bloc<CuttingEvent, CuttingState> {
  CuttingBloc({
    required this.getList,
    required this.create,
    required this.update,
    required this.delete,
  }) : super(CuttingInitial()) {
    on<LoadCuttingList>((event, emit) async {
      _currentPage = 0;
      _hasMore = true;
      emit(CuttingLoading());
      final result = await getList(page: _currentPage, limit: 20);
      result.fold((error) => emit(CuttingError(error)), (items) {
        _items = items;
        _hasMore = items.length == 20;
        emit(CuttingLoaded(_items));
      });
    });

    on<LoadMoreCuttingList>((event, emit) async {
      if (!_hasMore) return;
      _currentPage++;
      final result = await getList(page: _currentPage, limit: 20);
      result.fold((error) => emit(CuttingError(error)), (items) {
        _items.addAll(items);
        _hasMore = items.length == 20;
        emit(CuttingLoaded(List.from(_items)));
      });
    });

    on<CreateCutting>((event, emit) async {
      emit(CuttingLoading());
      final result = await create(event.item);
      result.fold((error) => emit(CuttingError(error)), (_) {
        emit(CuttingSuccess('Cutting record created'));
        add(LoadCuttingList());
      });
    });

    on<UpdateCutting>((event, emit) async {
      emit(CuttingLoading());
      final result = await update(event.item);
      result.fold((error) => emit(CuttingError(error)), (_) {
        emit(CuttingSuccess('Cutting record updated'));
        add(LoadCuttingList());
      });
    });

    on<DeleteCutting>((event, emit) async {
      emit(CuttingLoading());
      final result = await delete(event.id);
      result.fold((error) => emit(CuttingError(error)), (_) {
        emit(CuttingSuccess('Cutting record deleted'));
        add(LoadCuttingList());
      });
    });
  }

  final GetCuttingListUseCase getList;
  final CreateCuttingUseCase create;
  final UpdateCuttingUseCase update;
  final DeleteCuttingUseCase delete;

  int _currentPage = 0;
  bool _hasMore = true;
  List<CuttingEntity> _items = [];
}

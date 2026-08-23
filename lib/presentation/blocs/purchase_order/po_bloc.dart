import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/purchase_order/create_po_usecase.dart';
import '../../../domain/usecases/purchase_order/delete_po_usecase.dart';
import '../../../domain/usecases/purchase_order/get_po_by_tag_usecase.dart';
import '../../../domain/usecases/purchase_order/get_po_list_usecase.dart';
import '../../../domain/usecases/purchase_order/update_po_usecase.dart';
import '../../../domain/entities/po_entity.dart';
import 'po_event.dart';
import 'po_state.dart';

class POBloc extends Bloc<POEvent, POState> {
  POBloc({
    required this.getList,
    required this.getByTag,
    required this.create,
    required this.update,
    required this.delete,
  }) : super(POInitial()) {
    on<LoadPOList>((event, emit) async {
      _currentPage = 0;
      _hasMore = true;
      emit(POLoading());
      final result = await getList(page: _currentPage, limit: 20);
      result.fold(
        (error) => emit(POError(error)),
        (items) {
          _items = items;
          _hasMore = items.length == 20;
          emit(POLoaded(_items));
        }
      );
    });

    on<LoadMorePOList>((event, emit) async {
      if (!_hasMore) return;
      _currentPage++;
      final result = await getList(page: _currentPage, limit: 20);
      result.fold(
        (error) => emit(POError(error)),
        (items) {
          _items.addAll(items);
          _hasMore = items.length == 20;
          emit(POLoaded(List.from(_items)));
        }
      );
    });

    on<LoadPOByTag>((event, emit) async {
      emit(POLoading());
      final result = await getByTag(event.tag);
      result.fold(
        (error) => emit(POError(error)),
        (items) => emit(POLoaded(items))
      );
    });

    on<CreatePO>((event, emit) async {
      emit(POLoading());
      final result = await create(event.item);
      result.fold(
        (error) => emit(POError(error)),
        (_) {
          emit(POSuccess('Purchase Order created'));
          add(LoadPOList());
        }
      );
    });

    on<UpdatePO>((event, emit) async {
      emit(POLoading());
      final result = await update(event.item);
      result.fold(
        (error) => emit(POError(error)),
        (_) {
          emit(POSuccess('Purchase Order updated'));
          add(LoadPOList());
        }
      );
    });

    on<DeletePO>((event, emit) async {
      emit(POLoading());
      final result = await delete(event.id);
      result.fold(
        (error) => emit(POError(error)),
        (_) {
          emit(POSuccess('Purchase Order deleted'));
          add(LoadPOList());
        }
      );
    });
  }

  final GetPOListUseCase getList;
  final GetPOByTagUseCase getByTag;
  final CreatePOUseCase create;
  final UpdatePOUseCase update;
  final DeletePOUseCase delete;

  int _currentPage = 0;
  bool _hasMore = true;
  List<POEntity> _items = [];
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/purchase_order/create_po_usecase.dart';
import '../../../domain/usecases/purchase_order/delete_po_usecase.dart';
import '../../../domain/usecases/purchase_order/get_po_by_tag_usecase.dart';
import '../../../domain/usecases/purchase_order/get_po_list_usecase.dart';
import '../../../domain/usecases/purchase_order/update_po_usecase.dart';
import '../../../domain/usecases/purchase_order/validate_po_quantity_usecase.dart';
import '../../../domain/usecases/master_lc/get_master_lc_by_tag_usecase.dart';
import '../../../domain/entities/po_entity.dart';
import '../../../domain/entities/master_lc_entity.dart';
import 'po_event.dart';
import 'po_state.dart';

class POBloc extends Bloc<POEvent, POState> {
  POBloc({
    required this.getList,
    required this.getByTag,
    required this.create,
    required this.update,
    required this.delete,
    required this.validateQuantity,
    this.getMasterLCByTag,
  }) : super(POInitial()) {
    on<LoadPOList>((event, emit) async {
      _currentPage = 0;
      _hasMore = true;
      emit(POLoading());
      final result = await getList(page: _currentPage, limit: 20);
      if (emit.isDone) return;
      result.fold(
        (error) {
          _loadingMore = false;
          emit(POError(error));
        },
        (items) {
          _loadingMore = false;
          _items = List.from(items);
          _hasMore = items.length == 20;
          emit(_items.isEmpty ? POEmpty() : POLoaded(List.from(_items)));
        }
      );
    });

    on<SearchPO>((event, emit) {
      final query = event.query.trim().toLowerCase();
      if (query.isEmpty) {
        emit(_items.isEmpty ? POEmpty() : POLoaded(List.from(_items)));
        return;
      }
      emit(POSearching());
      final filtered = _items.where((item) =>
          item.poNo.toLowerCase().contains(query) ||
          item.tagNo.toLowerCase().contains(query) ||
          item.company.toLowerCase().contains(query) ||
          item.project.toLowerCase().contains(query)).toList();
      emit(filtered.isEmpty ? POEmpty() : POSearchLoaded(filtered, query));
    });
    on<ClearSearch>((event, emit) => emit(
          _items.isEmpty ? POEmpty() : POLoaded(List.from(_items)),
        ));
    on<RefreshPOList>((event, emit) async {
      emit(PORefreshing());
      add(LoadPOList());
    });

    on<LoadPODetail>((event, emit) async {
      emit(PODetailLoading());
      var item = event.initialItem;
      if (item == null || item.id != event.id) {
        final result = await getList(page: 0, limit: 1000);
        item = result.fold<POEntity?>(
          (_) => null,
          (items) => items.cast<POEntity?>().firstWhere(
                (candidate) => candidate?.id == event.id,
                orElse: () => null,
              ),
        );
      }
      if (item == null) {
        emit(PODetailError('Purchase order not found'));
        return;
      }
      final loadedItem = item;
      if (getMasterLCByTag == null) {
        emit(PODetailError('Master LC lookup is unavailable'));
        return;
      }
      final masterResult = await getMasterLCByTag!(loadedItem.tagNo);
      if (emit.isDone) return;
      final master = masterResult.fold<MasterLCEntity?>(
        (error) => null,
        (value) => value,
      );
      if (master == null) {
        emit(PODetailError('Master LC not found for tag ${loadedItem.tagNo}'));
        return;
      }
      final ordersResult = await getByTag(loadedItem.tagNo);
      if (emit.isDone) return;
      ordersResult.fold(
        (error) => emit(PODetailError(error)),
        (orders) => emit(
          PODetailLoaded(
            loadedItem,
            master,
            totalTagQuantity: orders.fold<int>(
              0,
              (sum, order) => sum + order.totalQuantity,
            ),
            totalTagValue: orders.fold<double>(
              0,
              (sum, order) => sum + order.totalValue,
            ),
          ),
        ),
      );
    });

    on<LoadMorePOList>((event, emit) async {
      if (!_hasMore || _loadingMore) return;
      _loadingMore = true;
      final pageToLoad = _currentPage + 1;
      final result = await getList(page: pageToLoad, limit: 20);
      if (emit.isDone) {
        _loadingMore = false;
        return;
      }
      result.fold(
        (error) {
          _loadingMore = false;
          emit(POError(error));
        },
        (items) {
          _loadingMore = false;
          _currentPage = pageToLoad;
          _items.addAll(items);
          _hasMore = items.length == 20;
          emit(POLoaded(List.from(_items)));
        }
      );
    });

    on<LoadPOByTag>((event, emit) async {
      emit(POLoading());
      final result = await getByTag(event.tag);
      if (emit.isDone) return;
      result.fold(
        (error) => emit(POError(error)),
        (items) => emit(POLoaded(items))
      );
    });

    on<CreatePO>((event, emit) async {
      emit(POLoading());
      final result = await create(event.item);
      if (emit.isDone) return;
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
      if (emit.isDone) return;
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
      if (emit.isDone) return;
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
  final ValidatePOQuantityUseCase validateQuantity;
  final GetMasterLCByTagUseCase? getMasterLCByTag;

  int _currentPage = 0;
  bool _hasMore = true;
  bool _loadingMore = false;
  List<POEntity> _items = [];

  Future<POAvailability?> getAvailability(POEntity item) =>
      validateQuantity.availability(item);

}

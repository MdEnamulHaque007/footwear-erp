import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import '../../../domain/usecases/master_lc/create_master_lc_usecase.dart';
import '../../../domain/usecases/master_lc/delete_master_lc_usecase.dart';
import '../../../domain/usecases/master_lc/get_master_lc_list_usecase.dart';
import '../../../domain/usecases/master_lc/update_master_lc_usecase.dart';
import '../../../domain/usecases/master_lc/get_master_lc_by_id_usecase.dart';
import '../../../domain/usecases/purchase_order/get_po_by_tag_usecase.dart';
import '../../../domain/entities/master_lc_entity.dart';
import 'master_lc_event.dart';
import 'master_lc_state.dart';

class MasterLCBloc extends Bloc<MasterLCEvent, MasterLCState> {
  MasterLCBloc({
    required this.getList,
    required this.create,
    required this.update,
    required this.delete,
    this.getById,
    this.getPOByTag,
  }) : super(MasterLCInitial()) {
    on<LoadMasterLCList>((event, emit) async {
      _currentPage = 0;
      _hasMore = true;
      emit(MasterLCLoading());
      final result = await getList(page: _currentPage, limit: event.limit);
      if (emit.isDone) return;
      result.fold((error) => emit(MasterLCError(error)), (items) {
        _items = items;
        _hasMore = items.length == event.limit;
        emit(MasterLCLoaded(_items));
      });
    });

    on<LoadMoreMasterLC>((event, emit) async {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
      _currentPage++;
      try {
        final result = await getList(page: _currentPage, limit: 20);
        if (emit.isDone) return;
        result.fold((error) => emit(MasterLCError(error)), (items) {
          _items.addAll(items);
          _hasMore = items.length == 20;
          emit(MasterLCLoaded(List.from(_items)));
        });
      } finally {
        _isLoadingMore = false;
      }
    });

    on<CreateMasterLC>((event, emit) async {
      emit(MasterLCLoading());
      final result = await create(event.item);
      if (emit.isDone) return;
      result.fold((error) => emit(MasterLCError(error)), (_) {
        emit(MasterLCSuccess('Master LC created'));
        add(LoadMasterLCList()); // Reload
      });
    });

    on<UpdateMasterLC>((event, emit) async {
      emit(MasterLCLoading());
      final result = await update(event.item);
      if (emit.isDone) return;
      result.fold((error) => emit(MasterLCError(error)), (_) {
        emit(MasterLCUpdateSuccess('Master LC updated'));
        add(LoadMasterLCList()); // Reload
      });
    });

    on<DeleteMasterLC>((event, emit) async {
      emit(MasterLCLoading());
      final result = await delete(event.id);
      if (emit.isDone) return;
      result.fold((error) => emit(MasterLCError(error)), (_) {
        emit(MasterLCDeleteSuccess('Master LC deleted'));
        add(LoadMasterLCList()); // Reload
      });

    });
    on<LoadMasterLCDetail>((event, emit) async {
      emit(MasterLCDetailLoading());
      final itemResult = event.initialItem != null
          ? Right<String, MasterLCEntity?>(event.initialItem)
          : getById == null
              ? const Left<String, MasterLCEntity?>('Master LC lookup unavailable')
              : await getById!(event.id);
      final item = itemResult.fold<MasterLCEntity?>((_) => null, (value) => value);
      if (emit.isDone) return;
      if (item == null) {
        emit(MasterLCDetailError('Master LC not found'));
        return;
      }
      if (getPOByTag == null) {
        emit(MasterLCDetailLoaded(
          masterLC: item,
          purchaseOrders: const [],
          totalPOQuantity: 0,
          totalPOValue: 0,
        ));
        return;
      }
      final ordersResult = await getPOByTag!(item.tagNo);
      if (emit.isDone) return;
      ordersResult.fold(
        (error) => emit(MasterLCDetailError(error)),
        (orders) {
          final quantity =
              orders.fold<int>(0, (sum, po) => sum + po.totalQuantity);
          final value =
              orders.fold<double>(0, (sum, po) => sum + po.totalValue);
          emit(MasterLCDetailLoaded(
            masterLC: item,
            purchaseOrders: orders,
            totalPOQuantity: quantity,
            totalPOValue: value,
          ));
        },
      );
    });
  }

  final GetMasterLCListUseCase getList;
  final CreateMasterLCUseCase create;
  final UpdateMasterLCUseCase update;
  final DeleteMasterLCUseCase delete;
  final GetMasterLCByIdUseCase? getById;
  final GetPOByTagUseCase? getPOByTag;

  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<MasterLCEntity> _items = [];
}

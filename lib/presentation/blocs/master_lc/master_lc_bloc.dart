import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/master_lc/create_master_lc_usecase.dart';
import '../../../domain/usecases/master_lc/delete_master_lc_usecase.dart';
import '../../../domain/usecases/master_lc/get_master_lc_list_usecase.dart';
import '../../../domain/usecases/master_lc/update_master_lc_usecase.dart';
import '../../../domain/entities/master_lc_entity.dart';
import 'master_lc_event.dart';
import 'master_lc_state.dart';

class MasterLCBloc extends Bloc<MasterLCEvent, MasterLCState> {
  MasterLCBloc({
    required this.getList,
    required this.create,
    required this.update,
    required this.delete,
  }) : super(MasterLCInitial()) {
    on<LoadMasterLCList>((event, emit) async {
      _currentPage = 0;
      _hasMore = true;
      emit(MasterLCLoading());
      final result = await getList(page: _currentPage, limit: 20);
      result.fold(
        (error) => emit(MasterLCError(error)),
        (items) {
          _items = items;
          _hasMore = items.length == 20;
          emit(MasterLCLoaded(_items));
        },
      );
    });

    on<LoadMoreMasterLC>((event, emit) async {
      if (!_hasMore) return;
      _currentPage++;
      final result = await getList(page: _currentPage, limit: 20);
      result.fold(
        (error) => emit(MasterLCError(error)),
        (items) {
          _items.addAll(items);
          _hasMore = items.length == 20;
          emit(MasterLCLoaded(List.from(_items)));
        },
      );
    });

    on<CreateMasterLC>((event, emit) async {
      emit(MasterLCLoading());
      final result = await create(event.item);
      result.fold(
        (error) => emit(MasterLCError(error)),
        (_) {
          emit(MasterLCSuccess('Master LC created'));
          add(LoadMasterLCList()); // Reload
        }
      );
    });

    on<UpdateMasterLC>((event, emit) async {
      emit(MasterLCLoading());
      final result = await update(event.item);
      result.fold(
        (error) => emit(MasterLCError(error)),
        (_) {
          emit(MasterLCSuccess('Master LC updated'));
          add(LoadMasterLCList()); // Reload
        }
      );
    });

    on<DeleteMasterLC>((event, emit) async {
      emit(MasterLCLoading());
      final result = await delete(event.id);
      result.fold(
        (error) => emit(MasterLCError(error)),
        (_) {
          emit(MasterLCSuccess('Master LC deleted'));
          add(LoadMasterLCList()); // Reload
        }
      );
    });
  }

  final GetMasterLCListUseCase getList;
  final CreateMasterLCUseCase create;
  final UpdateMasterLCUseCase update;
  final DeleteMasterLCUseCase delete;

  int _currentPage = 0;
  bool _hasMore = true;
  List<MasterLCEntity> _items = [];
}

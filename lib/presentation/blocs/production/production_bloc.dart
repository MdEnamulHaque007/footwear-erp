import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/production_entity.dart';
import '../../../domain/usecases/production/create_production_usecase.dart';
import '../../../domain/usecases/production/delete_production_usecase.dart';
import '../../../domain/usecases/production/get_production_list_usecase.dart';
import '../../../domain/usecases/production/update_production_usecase.dart';
import 'production_event.dart';
import 'production_state.dart';

class ProductionBloc extends Bloc<ProductionEvent, ProductionState> {
  ProductionBloc({
    required this.getList,
    required this.create,
    required this.update,
    required this.delete,
  }) : super(ProductionInitial()) {
    on<LoadProductionList>((event, emit) async {
      _currentPage = 0;
      _hasMore = true;
      emit(ProductionLoading());
      final result = await getList(page: _currentPage, limit: 20);
      result.fold((error) => emit(ProductionError(error)), (items) {
        _items = items;
        _hasMore = items.length == 20;
        emit(ProductionLoaded(_items));
      });
    });

    on<LoadMoreProductionList>((event, emit) async {
      if (!_hasMore) return;
      _currentPage++;
      final result = await getList(page: _currentPage, limit: 20);
      result.fold((error) => emit(ProductionError(error)), (items) {
        _items.addAll(items);
        _hasMore = items.length == 20;
        emit(ProductionLoaded(List.from(_items)));
      });
    });

    on<CreateProduction>((event, emit) async {
      emit(ProductionLoading());
      final result = await create(event.item);
      result.fold((error) => emit(ProductionError(error)), (_) {
        emit(ProductionSuccess('Production record created'));
        add(LoadProductionList());
      });
    });

    on<UpdateProduction>((event, emit) async {
      emit(ProductionLoading());
      final result = await update(event.item);
      result.fold((error) => emit(ProductionError(error)), (_) {
        emit(ProductionSuccess('Production record updated'));
        add(LoadProductionList());
      });
    });

    on<DeleteProduction>((event, emit) async {
      emit(ProductionLoading());
      final result = await delete(event.id);
      result.fold((error) => emit(ProductionError(error)), (_) {
        emit(ProductionSuccess('Production record deleted'));
        add(LoadProductionList());
      });
    });
  }

  final GetProductionListUseCase getList;
  final CreateProductionUseCase create;
  final UpdateProductionUseCase update;
  final DeleteProductionUseCase delete;

  int _currentPage = 0;
  bool _hasMore = true;
  List<ProductionEntity> _items = [];
}

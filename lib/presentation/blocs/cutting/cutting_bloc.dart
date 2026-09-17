import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/cutting_entity.dart';
import '../../../domain/entities/po_entity.dart';
import '../../../domain/repositories/i_cutting_repository.dart';
import '../../../domain/usecases/cutting/create_cutting_usecase.dart';
import '../../../domain/usecases/cutting/delete_cutting_usecase.dart';
import '../../../domain/usecases/cutting/get_cutting_list_usecase.dart';
import '../../../domain/usecases/cutting/update_cutting_usecase.dart';
import '../../../domain/usecases/cutting/get_po_no_list_usecase.dart';
import '../../../domain/usecases/cutting/get_po_by_no_usecase.dart';
import '../../../domain/usecases/cutting/get_po_list_for_dropdown_usecase.dart';
import '../../../domain/usecases/cutting/get_cumulative_cutting_usecase.dart';
import '../../../domain/usecases/cutting/validate_cutting_quantity_usecase.dart';
import 'cutting_event.dart';
import 'cutting_state.dart';

class CuttingBloc extends Bloc<CuttingEvent, CuttingState> {
  CuttingBloc({
    required this.getList,
    required this.create,
    required this.update,
    required this.delete,
    required this.getPONos,
    required this.getPOList,
    required this.getPOByNo,
    required this.getCumulative,
    required this.validateQuantity,
    required this.repository,
  }) : super(CuttingInitial()) {
    on<LoadCuttingList>((event, emit) async {
      _currentPage = 0;
      _hasMore = true;
      emit(CuttingLoading());
      final result = await getList(page: _currentPage, limit: event.limit);
      if (emit.isDone) return;
      result.fold((error) => emit(CuttingError(error)), (items) {
        _items = items;
        _hasMore = items.length == event.limit;
        emit(
          CuttingLoaded(_items, hasMore: _hasMore, currentPage: _currentPage),
        );
      });
    });

    on<LoadMoreCuttingList>((event, emit) async {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
      _currentPage++;
      try {
        final result = await getList(page: _currentPage, limit: 20);
        if (emit.isDone) return;
        result.fold((error) => emit(CuttingError(error)), (items) {
          _items.addAll(items);
          _hasMore = items.length == 20;
          emit(
            CuttingLoaded(
              List.from(_items),
              hasMore: _hasMore,
              currentPage: _currentPage,
            ),
          );
        });
      } finally {
        _isLoadingMore = false;
      }
    });

    on<SearchCutting>((event, emit) async {
      final normalized = event.query.trim().toLowerCase();
      final results = _items.where((item) {
        if (normalized.isEmpty) return true;
        return item.poNo.toLowerCase().contains(normalized) ||
            item.voucherNo.toLowerCase().contains(normalized) ||
            item.tagNo.toLowerCase().contains(normalized) ||
            item.article.toLowerCase().contains(normalized) ||
            item.color.toLowerCase().contains(normalized);
      }).toList();
      if (emit.isDone) return;
      emit(CuttingSearchLoaded(results));
    });
    on<ClearSearchCutting>((event, emit) async => add(const LoadCuttingList()));
    on<RefreshCutting>((event, emit) async {
      _currentPage = 0;
      _hasMore = true;
      add(LoadCuttingList(limit: event.limit));
    });
    on<LoadCuttingDetail>((event, emit) async {
      emit(CuttingLoading());
      final itemResult = await repository.byId(event.id);
      if (emit.isDone) return;
      final item =
          itemResult.fold((_) => null, (value) => value) ?? event.initialItem;
      if (item == null) {
        emit(CuttingError('Cutting record not found'));
        return;
      }
      final relatedResult = await repository.byLine(
        poNo: item.poNo,
        article: item.article,
        color: item.color,
      );
      if (emit.isDone) return;
      relatedResult.fold((error) => emit(CuttingError(error)), (related) {
        final total = related.fold<int>(
          0,
          (sum, entry) => sum + entry.cuttingQuantity,
        );
        emit(
          CuttingDetailLoaded(
            item: item,
            related: related,
            totalQuantity: total,
            availableQuantity: (item.poQuantity - total)
                .clamp(0, item.poQuantity)
                .toInt(),
          ),
        );
      });
    });

    on<CreateCutting>((event, emit) async {
      emit(CuttingLoading());
      final result = await create(event.item);
      if (emit.isDone) return;
      result.fold((error) => emit(CuttingError(error)), (_) {
        emit(CuttingSuccess('Cutting record created'));
        add(LoadCuttingList());
      });
    });

    on<UpdateCutting>((event, emit) async {
      emit(CuttingLoading());
      final result = await update(event.item);
      if (emit.isDone) return;
      result.fold((error) => emit(CuttingError(error)), (_) {
        emit(CuttingSuccess('Cutting record updated'));
        add(LoadCuttingList());
      });
    });

    on<DeleteCutting>((event, emit) async {
      emit(CuttingLoading());
      final result = await delete(event.id);
      if (emit.isDone) return;
      result.fold((error) => emit(CuttingError(error)), (_) {
        emit(CuttingSuccess('Cutting record deleted'));
        add(LoadCuttingList());
      });
    });

    on<LoadPONoList>(_onLoadPONoList);
    on<SelectPO>((event, emit) async {
      final result = await getPOByNo(event.poNo);
      if (emit.isDone) return;
      result.fold((error) => emit(CuttingError(error)), (po) {
        if (po == null) {
          emit(CuttingError('PO not found'));
          return;
        }
        emit(
          POSelected(po.poNo, po.tagNo, po.company, po.project, _articles(po)),
        );
      });
    });
    on<LoadPOArticles>((event, emit) async {
      final result = await getPOByNo(event.poNo);
      if (emit.isDone) return;
      result.fold(
        (error) => emit(CuttingError(error)),
        (po) => emit(ArticleListLoaded(po == null ? const [] : _articles(po))),
      );
    });
    on<LoadArticleColors>((event, emit) async {
      final result = await getPOByNo(event.poNo);
      if (emit.isDone) return;
      result.fold(
        (error) => emit(CuttingError(error)),
        (po) => emit(
          ColorListLoaded(
            po == null
                ? const []
                : po.effectiveLineItems
                      .where(
                        (item) =>
                            _normalize(item.article) ==
                            _normalize(event.article),
                      )
                      .map((item) => item.color.trim())
                      .where((value) => value.isNotEmpty)
                      .toSet()
                      .toList(),
          ),
        ),
      );
    });
    on<LoadPOQuantity>((event, emit) async {
      final result = await getPOByNo(event.poNo);
      if (emit.isDone) return;
      if (result.isLeft()) {
        result.fold((error) => emit(CuttingError(error)), (_) {});
        return;
      }
      final po = result.getOrElse(() => null);
      final matchingItems =
          po?.effectiveLineItems
              .where(
                (line) =>
                    _normalize(line.article) == _normalize(event.article) &&
                    _normalize(line.color) == _normalize(event.color),
              )
              .toList() ??
          const <POLineItemEntity>[];
      if (matchingItems.isEmpty) {
        emit(AvailableQuantityLoaded(0, 0));
        return;
      }
      final item = matchingItems.first;
      final cumulative = await getCumulative(
        poNo: event.poNo,
        article: event.article,
        color: event.color,
        excludingId: event.excludingId,
      );
      if (emit.isDone) return;
      emit(
        AvailableQuantityLoaded(
          item.poQuantity - cumulative,
          item.poQuantity,
        ),
      );
    });
    on<ValidateCutting>((event, emit) async {
      final result = await validateQuantity(
        poNo: event.poNo,
        article: event.article,
        color: event.color,
        poQuantity: event.poQuantity,
        candidateQuantity: event.quantity,
        excludingId: event.excludingId,
      );
      if (emit.isDone) return;
      result.fold(
        (error) => emit(CuttingValidationError(error)),
        (_) => emit(CuttingValidationSuccess()),
      );
    });
  }

  Future<void> _onLoadPONoList(
    LoadPONoList event,
    Emitter<CuttingState> emit,
  ) async {
    emit(CuttingLoading());
    final result = await getPOList();
    if (emit.isDone) return;
    result.fold(
      (error) => emit(CuttingError(error)),
      (items) => emit(
        PONoListLoaded(
          items
              .map((po) => po.poNo)
              .where((no) => no.isNotEmpty)
              .toSet()
              .toList(),
          items,
        ),
      ),
    );
  }

  String _normalize(String value) => value.trim().toLowerCase();

  List<String> _articles(POEntity po) => po.effectiveLineItems
      .map((item) => item.article.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();

  final GetCuttingListUseCase getList;
  final CreateCuttingUseCase create;
  final UpdateCuttingUseCase update;
  final DeleteCuttingUseCase delete;
  final GetPONoListUseCase getPONos;
  final GetPOListForDropdownUseCase getPOList;
  final GetPOByNoUseCase getPOByNo;
  final GetCumulativeCuttingUseCase getCumulative;
  final ValidateCuttingQuantityUseCase validateQuantity;
  final ICuttingRepository repository;

  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<CuttingEntity> _items = [];
}

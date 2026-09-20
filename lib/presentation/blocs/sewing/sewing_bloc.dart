import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/sewing/sewing_model.dart';
import '../../../domain/entities/po_entity.dart';
import '../../../domain/entities/sewing_entity.dart';
import '../../../domain/repositories/i_sewing_repository.dart';
import '../../../domain/usecases/sewing/create_sewing_usecase.dart';
import '../../../domain/usecases/sewing/delete_sewing_usecase.dart';
import '../../../domain/usecases/sewing/get_cumulative_cutting_usecase.dart';
import '../../../domain/usecases/sewing/get_cumulative_sewing_usecase.dart';
import '../../../domain/usecases/sewing/get_po_by_no_usecase.dart';
import '../../../domain/usecases/sewing/get_po_list_for_dropdown_usecase.dart';
import '../../../domain/usecases/sewing/get_sewing_list_usecase.dart';
import '../../../domain/usecases/sewing/update_sewing_usecase.dart';
import '../../../domain/usecases/sewing/validate_sewing_quantity_usecase.dart';
import 'sewing_event.dart';
import 'sewing_state.dart';

class SewingBloc extends Bloc<SewingEvent, SewingState> {
  SewingBloc({
    required this.getList,
    required this.create,
    required this.update,
    required this.delete,
    required this.getPOList,
    required this.getPOByNo,
    required this.getCumulativeCutting,
    required this.getCumulativeSewing,
    required this.validateQuantity,
    required this.repository,
  }) : super(SewingInitial()) {
    on<LoadSewingList>((event, emit) async {
      _currentPage = 0;
      _hasMore = true;
      emit(SewingLoading());
      final result = await getList(page: _currentPage, limit: 20);
      if (emit.isDone) return;
      result.fold((error) => emit(SewingError(error)), (items) {
        _items = items;
        _hasMore = items.length == 20;
        emit(
          SewingLoaded(_items, hasMore: _hasMore, currentPage: _currentPage),
        );
      });
    });

    on<LoadMoreSewingList>((event, emit) async {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
      _currentPage++;
      try {
        final result = await getList(page: _currentPage, limit: 20);
        if (emit.isDone) return;
        result.fold((error) => emit(SewingError(error)), (items) {
          _items.addAll(items);
          _hasMore = items.length == 20;
          emit(
            SewingLoaded(
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

    on<SearchSewing>((event, emit) async {
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
      emit(SewingSearchLoaded(results));
    });
    on<ClearSearchSewing>((event, emit) async => add(LoadSewingList()));
    on<RefreshSewing>((event, emit) async {
      _currentPage = 0;
      _hasMore = true;
      add(LoadSewingList());
    });

    on<CreateSewing>((event, emit) async {
      emit(SewingLoading());
      final result = await create(event.item);
      if (emit.isDone) return;
      result.fold((error) => emit(SewingError(error)), (_) {
        emit(SewingSuccess('Sewing record created'));
        add(LoadSewingList());
      });
    });

    on<UpdateSewing>((event, emit) async {
      emit(SewingLoading());
      final result = await update(event.item);
      if (emit.isDone) return;
      result.fold((error) => emit(SewingError(error)), (_) {
        emit(SewingSuccess('Sewing record updated'));
        add(LoadSewingList());
      });
    });

    on<DeleteSewing>((event, emit) async {
      emit(SewingLoading());
      final result = await delete(event.id);
      if (emit.isDone) return;
      result.fold((error) => emit(SewingError(error)), (_) {
        emit(SewingSuccess('Sewing record deleted'));
        add(LoadSewingList());
      });
    });

    // Registered at the top level (never nested) so the form's very first
    // PO Dropdown load is always dispatched.
    on<LoadPONoList>(_onLoadPONoList);

    on<SelectPO>((event, emit) async {
      final result = await getPOByNo(event.poNo);
      if (emit.isDone) return;
      result.fold((error) => emit(SewingError(error)), (po) {
        if (po == null) {
          emit(SewingError('PO not found'));
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
        (error) => emit(SewingError(error)),
        (po) => emit(ArticleListLoaded(po == null ? const [] : _articles(po))),
      );
    });

    on<LoadSewingDetail>((event, emit) async {
      emit(SewingLoading());
      final itemResult = await repository.byId(event.id);
      if (emit.isDone) return;
      final item =
          itemResult.fold((_) => null, (value) => value) ?? event.initialItem;
      if (item == null) {
        emit(SewingError('Sewing record not found'));
        return;
      }
      final relatedResult = await repository.byLine(
        poNo: item.poNo,
        article: item.article,
        color: item.color,
      );
      if (emit.isDone) return;
      final cuttingResult = await getCumulativeCutting(
        poNo: item.poNo,
        article: item.article,
        color: item.color,
        upToDate: item.sewingDate,
      );
      if (emit.isDone) return;
      if (relatedResult.isLeft() || cuttingResult.isLeft()) {
        emit(SewingError('Unable to load sewing details'));
        return;
      }
      final related = relatedResult.getOrElse(() => const <SewingModel>[])
          .cast<SewingEntity>();
      final cuttingQty = cuttingResult.getOrElse(() => 0);
      final total = related.fold<int>(
        0,
        (sum, entry) => sum + entry.sewingQuantity,
      );
      emit(
        SewingDetailLoaded(
          item: item,
          related: related,
          cuttingQuantity: cuttingQty,
          totalSewingQuantity: total,
          availableQuantity: (cuttingQty - total).clamp(0, cuttingQty).toInt(),
        ),
      );
    });

    on<LoadArticleColors>((event, emit) async {
      final result = await getPOByNo(event.poNo);
      if (emit.isDone) return;
      result.fold((error) => emit(SewingError(error)), (po) {
        final colors = po == null
            ? const <String>[]
            : po.effectiveLineItems
                  .where(
                    (item) =>
                        _normalize(item.article) == _normalize(event.article),
                  )
                  .map((item) => item.color.trim())
                  .where((value) => value.isNotEmpty)
                  .toSet()
                  .toList();
        emit(ColorListLoaded(colors));
      });
    });

    on<LoadAvailableQuantity>((event, emit) async {
      final cuttingResult = await getCumulativeCutting(
        poNo: event.poNo,
        article: event.article,
        color: event.color,
        upToDate: event.sewingDate,
      );
      if (emit.isDone) return;
      if (cuttingResult.isLeft()) {
        cuttingResult.fold((error) => emit(SewingError(error)), (_) {});
        return;
      }
      final sewingResult = await getCumulativeSewing(
        poNo: event.poNo,
        article: event.article,
        color: event.color,
        excludeId: event.excludeId,
      );
      if (emit.isDone) return;
      if (sewingResult.isLeft()) {
        sewingResult.fold((error) => emit(SewingError(error)), (_) {});
        return;
      }
      final cuttingQty = cuttingResult.getOrElse(() => 0);
      final sewingQty = sewingResult.getOrElse(() => 0);
      emit(
        AvailableQuantityLoaded(
          cuttingQty: cuttingQty,
          sewingQty: sewingQty,
          availableQty: (cuttingQty - sewingQty).clamp(0, cuttingQty).toInt(),
        ),
      );
    });

    on<ValidateSewing>((event, emit) async {
      final error = await validateQuantity(
        poNo: event.poNo,
        article: event.article,
        color: event.color,
        candidateQuantity: event.quantity,
        sewingDate: event.sewingDate,
        excludeId: event.excludeId,
      );
      if (emit.isDone) return;
      if (error == null) {
        emit(SewingValidationSuccess());
      } else {
        emit(SewingValidationError(error));
      }
    });
  }

  Future<void> _onLoadPONoList(
    LoadPONoList event,
    Emitter<SewingState> emit,
  ) async {
    emit(SewingLoading());
    final result = await getPOList();
    if (emit.isDone) return;
    result.fold(
      (error) => emit(SewingError(error)),
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

  final GetSewingListUseCase getList;
  final CreateSewingUseCase create;
  final UpdateSewingUseCase update;
  final DeleteSewingUseCase delete;
  final GetSewingPOListForDropdownUseCase getPOList;
  final GetSewingPOByNoUseCase getPOByNo;
  final GetCumulativeCuttingUseCase getCumulativeCutting;
  final GetCumulativeSewingUseCase getCumulativeSewing;
  final ValidateSewingQuantityUseCase validateQuantity;
  final ISewingRepository repository;

  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<SewingEntity> _items = [];
}


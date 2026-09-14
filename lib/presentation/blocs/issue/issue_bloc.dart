import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/issue/issue_model.dart';
import '../../../data/models/purchase_order/po_model.dart';
import '../../../domain/entities/issue_entity.dart';
import '../../../domain/entities/po_entity.dart';
import '../../../domain/repositories/i_issue_repository.dart';
import '../../../domain/usecases/issue/create_issue_usecase.dart';
import '../../../domain/usecases/issue/delete_issue_usecase.dart';
import '../../../domain/usecases/issue/get_issue_article_colors_usecase.dart';
import '../../../domain/usecases/issue/get_issue_availability_usecase.dart';
import '../../../domain/usecases/issue/get_issue_list_usecase.dart';
import '../../../domain/usecases/issue/get_issue_po_list_usecase.dart';
import '../../../domain/usecases/issue/update_issue_usecase.dart';
import '../../../domain/usecases/issue/validate_issue_quantity_usecase.dart';
import 'issue_event.dart';
import 'issue_state.dart';

class IssueBloc extends Bloc<IssueEvent, IssueState> {
  IssueBloc({
    required this.getList,
    required this.create,
    required this.update,
    required this.delete,
    required this.getPOList,
    required this.getArticleColors,
    required this.getAvailability,
    required this.validateQuantity,
    required this.repository,
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
        emit(IssueLoaded(_items, hasMore: _hasMore, currentPage: _currentPage));
      });
    });

    on<LoadMoreIssueList>((event, emit) async {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
      _currentPage++;
      try {
        final result = await getList(page: _currentPage, limit: 20);
        if (emit.isDone) return;
        result.fold((error) => emit(IssueError(error)), (items) {
          _items.addAll(items);
          _hasMore = items.length == 20;
          emit(
            IssueLoaded(
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

    on<SearchIssue>((event, emit) async {
      final normalized = event.query.trim().toLowerCase();
      final results = _items.where((item) {
        if (normalized.isEmpty) return true;
        return item.poNo.toLowerCase().contains(normalized) ||
            item.voucherNo.toLowerCase().contains(normalized) ||
            item.poTagNo.toLowerCase().contains(normalized) ||
            item.article.toLowerCase().contains(normalized) ||
            item.color.toLowerCase().contains(normalized);
      }).toList();
      if (emit.isDone) return;
      emit(IssueSearchLoaded(results));
    });
    on<ClearSearchIssue>((event, emit) async => add(LoadIssueList()));
    on<RefreshIssue>((event, emit) async {
      _currentPage = 0;
      _hasMore = true;
      add(LoadIssueList());
    });

    // Registered at the top level (never nested) so the form's very first
    // PO dropdown load is always dispatched.
    on<LoadPONoList>(_onLoadPONoList);
    on<SelectPO>(_onSelectPO);
    on<LoadPOArticles>(_onLoadPOArticles);
    on<LoadArticleColors>(_onLoadArticleColors);
    on<LoadIssueDetail>(_onLoadIssueDetail);

    on<LoadUnitPrice>((event, emit) async {
      final po = _findPO(event.poNo);
      final line = po?.effectiveLineItems
          .where(
            (item) =>
                _normalize(item.article) == _normalize(event.article) &&
                _normalize(item.color) == _normalize(event.color),
          )
          .firstOrNull;
      emit(UnitPriceLoaded(line?.unitPrice ?? 0));
    });

    on<LoadAvailableQuantity>((event, emit) async {
      final result = await getAvailability(
        poNo: event.poNo,
        article: event.article,
        color: event.color,
        issueDate: event.issueDate,
        excludeId: event.excludeId,
      );
      if (emit.isDone) return;
      result.fold((error) => emit(IssueError(error)), (availability) {
        emit(
          AvailableQuantityLoaded(
            productionQty: availability.productionQuantity,
            issueQty: availability.issueQuantity,
            availableQty: availability.availableQuantity,
          ),
        );
      });
    });

    on<ValidateIssue>((event, emit) async {
      final error = await validateQuantity(
        poTagNo: event.poTagNo,
        issueDate: event.issueDate,
        candidateQuantity: event.quantity,
        poNo: event.poNo,
        article: event.article,
        color: event.color,
        excludeId: event.excludeId,
      );
      if (emit.isDone) return;
      if (error == null) {
        emit(IssueValidationSuccess());
      } else {
        emit(IssueValidationError(error));
      }
    });
  }

  Future<void> _onLoadPONoList(
    LoadPONoList event,
    Emitter<IssueState> emit,
  ) async {
    emit(IssueLoading());
    // Production-sourced: only POs that already have a Production entry can be
    // issued.
    final result = await getPOList();
    if (emit.isDone) return;
    result.fold((error) => emit(IssueError(error)), (poNos) {
      _poNos = poNos;
      _poList = [];
      emit(PONoListLoaded(poNos, const []));
    });
  }

  /// PO header (Tag / Company / Project) for the auto-fill.
  Future<void> _onSelectPO(SelectPO event, Emitter<IssueState> emit) async {
    var po = _findPO(event.poNo);
    if (po == null) {
      final result = await repository.poByNo(event.poNo);
      if (emit.isDone) return;
      po = result.fold((error) {
        emit(IssueError(error));
        return null;
      }, (value) => value);
    }
    if (po == null) {
      emit(IssueError('PO not found'));
      return;
    }
    _poList = [POModel.fromEntity(po)];
    emit(POSelected(po.poNo, po.tagNo, po.company, po.project, _articles(po)));
  }

  /// Article list for the selected PO (Production-first, PO line fallback).
  Future<void> _onLoadPOArticles(
    LoadPOArticles event,
    Emitter<IssueState> emit,
  ) async {
    final productionResult = await getArticleColors(event.poNo);
    if (emit.isDone) return;
    if (productionResult.isRight()) {
      final lines = productionResult.getOrElse(() => const <ProductionLine>[]);
      if (lines.isNotEmpty) {
        _productionLines = lines;
        emit(ArticleListLoaded(_distinct(lines.map((line) => line.article))));
        return;
      }
    }
    final poResult = await repository.poByNo(event.poNo);
    if (emit.isDone) return;
    poResult.fold(
      (error) => emit(IssueError(error)),
      (po) => emit(ArticleListLoaded(po == null ? const [] : _articles(po))),
    );
  }

  /// Production-sourced: articles (and colors) that have actually been produced.
  Future<void> _onLoadArticleColors(
    LoadArticleColors event,
    Emitter<IssueState> emit,
  ) async {
    final result = await getArticleColors(event.poNo);
    if (emit.isDone) return;
    result.fold((error) => emit(IssueError(error)), (lines) {
      _productionLines = lines;
      emit(ArticleListLoaded(_distinct(lines.map((line) => line.article))));
      emit(ColorListLoaded(_colorsFor(lines, event.article)));
    });
  }

  Future<void> _onLoadIssueDetail(
    LoadIssueDetail event,
    Emitter<IssueState> emit,
  ) async {
    emit(IssueLoading());
    final itemResult = await repository.byId(event.id);
    if (emit.isDone) return;
    final item =
        itemResult.fold((_) => null, (value) => value) ?? event.initialItem;
    if (item == null) {
      emit(IssueError('Issue record not found'));
      return;
    }
    final relatedResult = await repository.byLine(
      poNo: item.poNo,
      article: item.article,
      color: item.color,
    );
    if (emit.isDone) return;
    final availabilityResult = await getAvailability(
      poNo: item.poNo,
      article: item.article,
      color: item.color,
      issueDate: item.issueDate,
    );
    if (emit.isDone) return;
    if (relatedResult.isLeft() || availabilityResult.isLeft()) {
      emit(IssueError('Unable to load issue details'));
      return;
    }
    final related = relatedResult.getOrElse(() => const <IssueModel>[]);
    final availability = availabilityResult.getOrElse(
      () => const IssueAvailability(
        productionQuantity: 0,
        issueQuantity: 0,
        availableQuantity: 0,
      ),
    );
    emit(
      IssueDetailLoaded(
        item: item,
        related: related,
        productionQuantity: availability.productionQuantity,
        totalIssueQuantity: availability.issueQuantity,
        availableQuantity: availability.availableQuantity,
      ),
    );
  }

  /// Case-insensitive dedupe of trimmed values, sorted, original case kept.
  List<String> _distinct(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed.toLowerCase())) result.add(trimmed);
    }
    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  List<String> _colorsFor(List<ProductionLine> lines, String article) =>
      _distinct(
        lines
            .where((line) => _normalize(line.article) == _normalize(article))
            .map((line) => line.color),
      );

  POEntity? _findPO(String poNo) {
    for (final po in _poList) {
      if (po.poNo == poNo) return po;
    }
    return null;
  }

  String _normalize(String value) => value.trim().toLowerCase();

  List<String> _articles(POEntity po) => po.effectiveLineItems
      .map((item) => item.article.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();

  /// Currently available PO numbers (Production-sourced).
  List<String> get poNos => List.unmodifiable(_poNos);

  /// Production lines cached for the last selected PO.
  List<ProductionLine> get productionLines =>
      List.unmodifiable(_productionLines);

  final GetIssueListUseCase getList;
  final CreateIssueUseCase create;
  final UpdateIssueUseCase update;
  final DeleteIssueUseCase delete;
  final GetIssuePOListUseCase getPOList;
  final GetIssueArticleColorsUseCase getArticleColors;
  final GetIssueAvailabilityUseCase getAvailability;
  final ValidateIssueQuantityUseCase validateQuantity;
  final IIssueRepository repository;

  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<POModel> _poList = [];
  List<String> _poNos = [];
  List<ProductionLine> _productionLines = [];
  List<IssueEntity> _items = [];
}

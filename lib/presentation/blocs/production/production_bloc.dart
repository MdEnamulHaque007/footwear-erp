/// ============================================================================
/// ফাইল: lib/presentation/blocs/production/production_bloc.dart
/// স্তর: Presentation BLoC | মডিউল: Production/Lasting
/// উদ্দেশ্য: Production/Lasting screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: ProductionBloc
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/production/production_model.dart';
import '../../../data/models/purchase_order/po_model.dart';
import '../../../domain/entities/production_entity.dart';
import '../../../domain/entities/po_entity.dart';
import '../../../domain/repositories/i_production_repository.dart';
import '../../../domain/usecases/production/create_production_usecase.dart';
import '../../../domain/usecases/production/delete_production_usecase.dart';
import '../../../domain/usecases/production/get_article_colors_usecase.dart';
import '../../../domain/usecases/production/get_production_availability_usecase.dart';
import '../../../domain/usecases/production/get_production_list_usecase.dart';
import '../../../domain/usecases/production/get_production_po_list_usecase.dart';
import '../../../domain/usecases/production/update_production_usecase.dart';
import '../../../domain/usecases/production/validate_production_quantity_usecase.dart';
import 'production_event.dart';
import 'production_state.dart';

class ProductionBloc extends Bloc<ProductionEvent, ProductionState> {
  ProductionBloc({
    required this.getList,
    required this.create,
    required this.update,
    required this.delete,
    required this.getPOList,
    required this.getArticleColors,
    required this.getAvailability,
    required this.validateQuantity,
    required this.repository,
  }) : super(ProductionInitial()) {
    on<LoadProductionList>((event, emit) async {
      _currentPage = 0;
      _hasMore = true;
      emit(ProductionLoading());
      final result = await getList(page: _currentPage, limit: 20);
      if (emit.isDone) return;
      result.fold((error) => emit(ProductionError(error)), (items) {
        _items = items;
        _hasMore = items.length == 20;
        emit(ProductionLoaded(_items));
      });
    });

    on<LoadMoreProductionList>((event, emit) async {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
      _currentPage++;
      try {
        final result = await getList(page: _currentPage, limit: 20);
        if (emit.isDone) return;
        result.fold((error) => emit(ProductionError(error)), (items) {
          _items.addAll(items);
          _hasMore = items.length == 20;
          emit(ProductionLoaded(List.from(_items)));
        });
      } finally {
        _isLoadingMore = false;
      }
    });

    on<CreateProduction>((event, emit) async {
      emit(ProductionLoading());
      final result = await create(event.item);
      if (emit.isDone) return;
      result.fold((error) => emit(ProductionError(error)), (_) {
        emit(ProductionSuccess('Production record created'));
        add(LoadProductionList());
      });
    });

    on<UpdateProduction>((event, emit) async {
      emit(ProductionLoading());
      final result = await update(event.item);
      if (emit.isDone) return;
      result.fold((error) => emit(ProductionError(error)), (_) {
        emit(ProductionSuccess('Production record updated'));
        add(LoadProductionList());
      });
    });

    on<DeleteProduction>((event, emit) async {
      emit(ProductionLoading());
      final result = await delete(event.id);
      if (emit.isDone) return;
      result.fold((error) => emit(ProductionError(error)), (_) {
        emit(ProductionSuccess('Production record deleted'));
        add(LoadProductionList());
      });
    });
    // Registered at the top level (never nested) so the form's very first
    // PO dropdown load is always dispatched.
    on<LoadPONoList>(_onLoadPONoList);
    on<SelectPO>(_onSelectPO);
    on<LoadPOArticles>(_onLoadPOArticles);
    on<LoadArticleColors>(_onLoadArticleColors);

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
        poTagNo: event.poTagNo,
        poNo: event.poNo,
        article: event.article,
        color: event.color,
        productionDate: event.productionDate,
        excludeId: event.excludeId,
      );
      if (emit.isDone) return;
      result.fold((error) => emit(ProductionError(error)), (availability) {
        emit(
          AvailableQuantityLoaded(
            sewingQty: availability.sewingQuantity,
            producedQty: availability.producedQuantity,
            availableQty: availability.availableQuantity,
          ),
        );
      });
    });

    on<ValidateProduction>((event, emit) async {
      final error = await validateQuantity(
        poTagNo: event.poTagNo,
        productionDate: event.productionDate,
        candidateQuantity: event.quantity,
        poNo: event.poNo,
        article: event.article,
        color: event.color,
        excludeId: event.excludeId,
      );
      if (emit.isDone) return;
      if (error == null) {
        emit(ProductionValidationSuccess());
      } else {
        emit(ProductionValidationError(error));
      }
    });

    on<SearchProduction>((event, emit) async {
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
      emit(ProductionSearchLoaded(results));
    });
    on<ClearSearchProduction>((event, emit) async => add(LoadProductionList()));
    on<RefreshProduction>((event, emit) async {
      _currentPage = 0;
      _hasMore = true;
      add(LoadProductionList());
    });

    // FIX: detail handler was never registered, so opening the detail screen
    // threw "Handler not found for LoadProductionDetail".
    on<LoadProductionDetail>(_onLoadProductionDetail);
  }

  Future<void> _onLoadProductionDetail(
    LoadProductionDetail event,
    Emitter<ProductionState> emit,
  ) async {
    emit(ProductionLoading());
    final itemResult = await repository.byId(event.id);
    if (emit.isDone) return;
    final item =
        itemResult.fold((_) => null, (value) => value) ?? event.initialItem;
    if (item == null) {
      emit(ProductionError('Production record not found'));
      return;
    }
    final relatedResult = await repository.byLine(
      poNo: item.poNo,
      article: item.article,
      color: item.color,
    );
    if (emit.isDone) return;
    final availabilityResult = await getAvailability(
      poTagNo: item.poTagNo,
      poNo: item.poNo,
      article: item.article,
      color: item.color,
      productionDate: item.productionDate,
    );
    if (emit.isDone) return;
    if (relatedResult.isLeft() || availabilityResult.isLeft()) {
      emit(ProductionError('Unable to load production details'));
      return;
    }
    final related = relatedResult.getOrElse(() => const <ProductionModel>[]);
    final availability = availabilityResult.getOrElse(
      () => const ProductionAvailability(
        sewingQuantity: 0,
        producedQuantity: 0,
        availableQuantity: 0,
      ),
    );
    emit(
      ProductionDetailLoaded(
        item: item,
        related: related,
        sewingQuantity: availability.sewingQuantity,
        totalProductionQuantity: availability.producedQuantity,
        availableQuantity: availability.availableQuantity,
      ),
    );
  }

  Future<void> _onLoadPONoList(
    LoadPONoList event,
    Emitter<ProductionState> emit,
  ) async {
    emit(ProductionLoading());
    // Sewing-sourced: only POs that already have a Sewing entry can be produced.
    final result = await getPOList();
    if (emit.isDone) return;
    result.fold((error) => emit(ProductionError(error)), (poNos) {
      _poNos = poNos;
      _poList = [];
      emit(PONoListLoaded(poNos, const []));
    });
  }

  /// Currently available PO numbers (Sewing-sourced).
  List<String> get poNos => List.unmodifiable(_poNos);

  /// Sewing lines cached for the last selected PO.
  List<SewingLine> get sewingLines => List.unmodifiable(_sewingLines);

  /// PO header (Tag / Company / Project) for the auto-fill.
  ///
  /// The PO document is looked up on demand because the dropdown is now driven
  /// by the Sewing entries rather than the PO collection.
  Future<void> _onSelectPO(
    SelectPO event,
    Emitter<ProductionState> emit,
  ) async {
    var po = _findPO(event.poNo);
    if (po == null) {
      final result = await repository.poByNo(event.poNo);
      if (emit.isDone) return;
      po = result.fold((error) {
        emit(ProductionError(error));
        return null;
      }, (value) => value);
    }
    if (po == null) {
      emit(ProductionError('PO not found'));
      return;
    }
    _poList = [POModel.fromEntity(po)];
    emit(POSelected(po.poNo, po.tagNo, po.company, po.project, _articles(po)));
  }

  /// Article list for the selected PO.
  ///
  /// Prefers the Sewing entries (only sewn articles can be produced) and falls
  /// back to the PO line items when the Sewing collection is still empty.
  Future<void> _onLoadPOArticles(
    LoadPOArticles event,
    Emitter<ProductionState> emit,
  ) async {
    final sewingResult = await getArticleColors(event.poNo);
    if (emit.isDone) return;
    if (sewingResult.isRight()) {
      final lines = sewingResult.getOrElse(() => const <SewingLine>[]);
      if (lines.isNotEmpty) {
        _sewingLines = lines;
        emit(ArticleListLoaded(_distinct(lines.map((line) => line.article))));
        return;
      }
    }
    final poResult = await repository.poByNo(event.poNo);
    if (emit.isDone) return;
    poResult.fold(
      (error) => emit(ProductionError(error)),
      (po) => emit(ArticleListLoaded(po == null ? const [] : _articles(po))),
    );
  }

  /// Sewing-sourced: articles (and their colors) that have actually been sewn.
  Future<void> _onLoadArticleColors(
    LoadArticleColors event,
    Emitter<ProductionState> emit,
  ) async {
    final result = await getArticleColors(event.poNo);
    if (emit.isDone) return;
    result.fold((error) => emit(ProductionError(error)), (lines) {
      _sewingLines = lines;
      emit(ArticleListLoaded(_distinct(lines.map((line) => line.article))));
      emit(ColorListLoaded(_colorsFor(lines, event.article)));
    });
  }

  /// Case-insensitive dedupe of trimmed values, sorted, original case kept.
  ///
  /// Prevents the `DropdownButton` "exactly one item with value" assertion when
  /// Firestore holds the same article/color with differing case or whitespace.
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

  List<String> _colorsFor(List<SewingLine> lines, String article) => _distinct(
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

  final GetProductionListUseCase getList;
  final CreateProductionUseCase create;
  final UpdateProductionUseCase update;
  final DeleteProductionUseCase delete;
  final GetProductionPOListUseCase getPOList;
  final GetArticleColorsUseCase getArticleColors;
  final GetProductionAvailabilityUseCase getAvailability;
  final ValidateProductionQuantityUseCase validateQuantity;
  final IProductionRepository repository;

  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<POModel> _poList = [];
  List<String> _poNos = [];
  List<SewingLine> _sewingLines = [];
  List<ProductionEntity> _items = [];
}

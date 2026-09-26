/// ============================================================================
/// ফাইল: lib/presentation/blocs/export/export_bloc.dart
/// স্তর: Presentation BLoC | মডিউল: Export
/// উদ্দেশ্য: Export screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: ExportBloc
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/export/export_model.dart';
import '../../../data/models/purchase_order/po_model.dart';
import '../../../domain/entities/export_entity.dart';
import '../../../domain/entities/po_entity.dart';
import '../../../domain/repositories/i_export_repository.dart';
import '../../../domain/usecases/export/create_export_usecase.dart';
import '../../../domain/usecases/export/delete_export_usecase.dart';
import '../../../domain/usecases/export/get_export_article_colors_usecase.dart';
import '../../../domain/usecases/export/get_export_availability_usecase.dart';
import '../../../domain/usecases/export/get_export_list_usecase.dart';
import '../../../domain/usecases/export/get_export_po_list_usecase.dart';
import '../../../domain/usecases/export/update_export_usecase.dart';
import '../../../domain/usecases/export/validate_export_quantity_usecase.dart';
import 'export_event.dart';
import 'export_state.dart';

class ExportBloc extends Bloc<ExportEvent, ExportState> {
  ExportBloc({
    required this.getList,
    required this.create,
    required this.update,
    required this.delete,
    required this.getPOList,
    required this.getArticleColors,
    required this.getAvailability,
    required this.validateQuantity,
    required this.repository,
  }) : super(ExportInitial()) {
    on<LoadExportList>((event, emit) async {
      _currentPage = 0;
      _hasMore = true;
      emit(ExportLoading());
      final result = await getList(page: _currentPage, limit: 20);
      if (emit.isDone) return;
      result.fold((error) => emit(ExportError(error)), (items) {
        _items = items;
        _hasMore = items.length == 20;
        emit(ExportLoaded(_items, hasMore: _hasMore, currentPage: _currentPage));
      });
    });

    on<LoadMoreExportList>((event, emit) async {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
      _currentPage++;
      try {
        final result = await getList(page: _currentPage, limit: 20);
        if (emit.isDone) return;
        result.fold((error) => emit(ExportError(error)), (items) {
          _items.addAll(items);
          _hasMore = items.length == 20;
          emit(
            ExportLoaded(
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

    on<CreateExport>((event, emit) async {
      emit(ExportLoading());
      final result = await create(event.item);
      if (emit.isDone) return;
      result.fold((error) => emit(ExportError(error)), (_) {
        emit(ExportSuccess('Export record created'));
        add(LoadExportList());
      });
    });

    on<UpdateExport>((event, emit) async {
      emit(ExportLoading());
      final result = await update(event.item);
      if (emit.isDone) return;
      result.fold((error) => emit(ExportError(error)), (_) {
        emit(ExportSuccess('Export record updated'));
        add(LoadExportList());
      });
    });

    on<DeleteExport>((event, emit) async {
      emit(ExportLoading());
      final result = await delete(event.id);
      if (emit.isDone) return;
      result.fold((error) => emit(ExportError(error)), (_) {
        emit(ExportSuccess('Export record deleted'));
        add(LoadExportList());
      });
    });

    on<SearchExport>((event, emit) async {
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
      emit(ExportSearchLoaded(results));
    });
    on<ClearSearchExport>((event, emit) async => add(LoadExportList()));
    on<RefreshExport>((event, emit) async {
      _currentPage = 0;
      _hasMore = true;
      add(LoadExportList());
    });

    // Registered at the top level (never nested) so the form's very first
    // PO dropdown load is always dispatched.
    on<LoadPONoList>(_onLoadPONoList);
    on<SelectPO>(_onSelectPO);
    on<LoadPOArticles>(_onLoadPOArticles);
    on<LoadArticleColors>(_onLoadArticleColors);
    on<LoadExportDetail>(_onLoadExportDetail);

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
        exportDate: event.exportDate,
        excludeId: event.excludeId,
      );
      if (emit.isDone) return;
      result.fold((error) => emit(ExportError(error)), (availability) {
        emit(
          AvailableQuantityLoaded(
            issueQty: availability.issueQuantity,
            exportQty: availability.exportQuantity,
            availableQty: availability.availableQuantity,
          ),
        );
      });
    });

    on<ValidateExport>((event, emit) async {
      final error = await validateQuantity(
        poNo: event.poNo,
        article: event.article,
        color: event.color,
        candidateQuantity: event.quantity,
        exportDate: event.exportDate,
        excludeId: event.excludeId,
      );
      if (emit.isDone) return;
      if (error == null) {
        emit(ExportValidationSuccess());
      } else {
        emit(ExportValidationError(error));
      }
    });
  }

  Future<void> _onLoadPONoList(
    LoadPONoList event,
    Emitter<ExportState> emit,
  ) async {
    emit(ExportLoading());
    // Issue-sourced: only POs that already have an Issue entry can be exported.
    final result = await getPOList();
    if (emit.isDone) return;
    result.fold((error) => emit(ExportError(error)), (poNos) {
      _poNos = poNos;
      _poList = [];
      emit(PONoListLoaded(poNos, const []));
    });
  }

  /// PO header (Tag / Company / Project) for the auto-fill.
  Future<void> _onSelectPO(SelectPO event, Emitter<ExportState> emit) async {
    var po = _findPO(event.poNo);
    if (po == null) {
      final result = await repository.poByNo(event.poNo);
      if (emit.isDone) return;
      po = result.fold((error) {
        emit(ExportError(error));
        return null;
      }, (value) => value);
    }
    if (po == null) {
      emit(ExportError('PO not found'));
      return;
    }
    _poList = [POModel.fromEntity(po)];
    emit(POSelected(po.poNo, po.tagNo, po.company, po.project, _articles(po)));
  }

  /// Article list for the selected PO (Issue-first, PO line fallback).
  Future<void> _onLoadPOArticles(
    LoadPOArticles event,
    Emitter<ExportState> emit,
  ) async {
    final issueResult = await getArticleColors(event.poNo);
    if (emit.isDone) return;
    if (issueResult.isRight()) {
      final lines = issueResult.getOrElse(() => const <IssueLine>[]);
      if (lines.isNotEmpty) {
        _issueLines = lines;
        emit(ArticleListLoaded(_distinct(lines.map((line) => line.article))));
        return;
      }
    }
    final poResult = await repository.poByNo(event.poNo);
    if (emit.isDone) return;
    poResult.fold(
      (error) => emit(ExportError(error)),
      (po) => emit(ArticleListLoaded(po == null ? const [] : _articles(po))),
    );
  }

  /// Issue-sourced: articles (and colors) that have actually been issued.
  Future<void> _onLoadArticleColors(
    LoadArticleColors event,
    Emitter<ExportState> emit,
  ) async {
    final result = await getArticleColors(event.poNo);
    if (emit.isDone) return;
    result.fold((error) => emit(ExportError(error)), (lines) {
      _issueLines = lines;
      emit(ArticleListLoaded(_distinct(lines.map((line) => line.article))));
      emit(ColorListLoaded(_colorsFor(lines, event.article)));
    });
  }

  Future<void> _onLoadExportDetail(
    LoadExportDetail event,
    Emitter<ExportState> emit,
  ) async {
    emit(ExportLoading());
    final itemResult = await repository.byId(event.id);
    if (emit.isDone) return;
    final item =
        itemResult.fold((_) => null, (value) => value) ?? event.initialItem;
    if (item == null) {
      emit(ExportError('Export record not found'));
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
      exportDate: item.exportDate,
    );
    if (emit.isDone) return;
    if (relatedResult.isLeft() || availabilityResult.isLeft()) {
      emit(ExportError('Unable to load export details'));
      return;
    }
    final related = relatedResult.getOrElse(() => const <ExportModel>[]);
    final availability = availabilityResult.getOrElse(
      () => const ExportAvailability(
        issueQuantity: 0,
        exportQuantity: 0,
        availableQuantity: 0,
      ),
    );
    emit(
      ExportDetailLoaded(
        item: item,
        related: related,
        issueQuantity: availability.issueQuantity,
        totalExportQuantity: availability.exportQuantity,
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

  List<String> _colorsFor(List<IssueLine> lines, String article) => _distinct(
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

  /// Currently available PO numbers (Issue-sourced).
  List<String> get poNos => List.unmodifiable(_poNos);

  /// Issue lines cached for the last selected PO.
  List<IssueLine> get issueLines => List.unmodifiable(_issueLines);

  final GetExportListUseCase getList;
  final CreateExportUseCase create;
  final UpdateExportUseCase update;
  final DeleteExportUseCase delete;
  final GetExportPOListUseCase getPOList;
  final GetExportArticleColorsUseCase getArticleColors;
  final GetExportAvailabilityUseCase getAvailability;
  final ValidateExportQuantityUseCase validateQuantity;
  final IExportRepository repository;

  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<POModel> _poList = [];
  List<String> _poNos = [];
  List<IssueLine> _issueLines = [];
  List<ExportEntity> _items = [];
}

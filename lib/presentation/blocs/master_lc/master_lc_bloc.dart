/// ============================================================================
/// ফাইল: lib/presentation/blocs/master_lc/master_lc_bloc.dart
/// স্তর: Presentation BLoC | মডিউল: Master LC
/// উদ্দেশ্য: Master LC screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: MasterLCBloc
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import '../../../domain/usecases/master_lc/create_master_lc_usecase.dart';
import '../../../domain/usecases/master_lc/delete_master_lc_usecase.dart';
import '../../../domain/usecases/master_lc/get_master_lc_list_usecase.dart';
import '../../../domain/usecases/master_lc/update_master_lc_usecase.dart';
import '../../../domain/usecases/master_lc/get_master_lc_by_id_usecase.dart';
import '../../../domain/usecases/master_lc/get_company_list_usecase.dart';
import '../../../domain/usecases/master_lc/get_project_list_usecase.dart';
import '../../../domain/usecases/purchase_order/get_po_by_tag_usecase.dart';
import '../../../core/constants/app_constants.dart';
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
    this.getProjects,
    this.getCompanies,
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
        emit(
          MasterLCLoaded(_items, hasMore: _hasMore, currentPage: _currentPage),
        );
      });
    });

    on<LoadMoreMasterLC>((event, emit) async {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
      // Retain the rows already on screen behind the footer spinner.
      final previousItems = List<MasterLCEntity>.from(_items);
      emit(MasterLCLoadingMore(previousItems, currentPage: _currentPage));
      try {
        final result = await getList(page: _currentPage + 1, limit: 20);
        if (emit.isDone) return;
        result.fold(
          (error) {
            // Keep the previous rows visible and disable the trigger so a failed
            // page cannot re-fire on every scroll frame; Refresh re-arms it.
            _hasMore = false;
            emit(
              MasterLCError(
                '$error\nPull to refresh or tap Retry to try again.',
              ),
            );
          },
          (items) {
            _currentPage++;
            _items.addAll(items);
            _hasMore = items.length == 20;
            emit(
              MasterLCLoaded(
                List.from(_items),
                hasMore: _hasMore,
                currentPage: _currentPage,
              ),
            );
          },
        );
      } catch (error) {
        if (emit.isDone) return;
        _hasMore = false;
        emit(MasterLCError('$error\nPull to refresh or tap Retry to try again.'));
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

    // Predefined Project / Company lists for the form dropdowns: the hardcoded
    // SRS seed values merged with whatever is already saved in Firestore, so
    // the list grows with real data (Option A + C hybrid).
    on<LoadPredefinedLists>((event, emit) async {
      final projects = <String>{...AppConstants.predefinedProjects};
      final companies = <String>{...AppConstants.predefinedCompanies};
      final projectsResult = await getProjects?.call();
      if (emit.isDone) return;
      projectsResult?.fold((_) {}, (values) => projects.addAll(values));
      final companiesResult = await getCompanies?.call();
      if (emit.isDone) return;
      companiesResult?.fold((_) {}, (values) => companies.addAll(values));
      emit(
        PredefinedListsLoaded(
          projects: _sorted(projects),
          companies: _sorted(companies),
        ),
      );
    });
  }

  /// Case-insensitive dedupe, sorted, original casing of the first occurrence.
  static List<String> _sorted(Iterable<String> values) {
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

  final GetMasterLCListUseCase getList;
  final CreateMasterLCUseCase create;
  final UpdateMasterLCUseCase update;
  final DeleteMasterLCUseCase delete;
  final GetMasterLCByIdUseCase? getById;
  final GetPOByTagUseCase? getPOByTag;
  final GetProjectListUseCase? getProjects;
  final GetCompanyListUseCase? getCompanies;

  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<MasterLCEntity> _items = [];
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/cutting_model.dart';
import '../data/repositories/cutting_repository.dart';
import '../core/failure.dart';

final cuttingRepositoryProvider = Provider<CuttingRepository>(
  (ref) => FirestoreCuttingRepository(),
);

class CuttingFilters {
  const CuttingFilters({this.poNo, this.from, this.to});

  final String? poNo;
  final DateTime? from;
  final DateTime? to;

  CuttingFilters copyWith({
    String? poNo,
    DateTime? from,
    DateTime? to,
    bool clearPoNo = false,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    return CuttingFilters(
      poNo: clearPoNo ? null : (poNo ?? this.poNo),
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
    );
  }
}

final cuttingFiltersProvider =
    StateProvider<CuttingFilters>((ref) => const CuttingFilters());

final cuttingsListProvider = StreamProvider<List<Cutting>>((ref) {
  final filters = ref.watch(cuttingFiltersProvider);
  return ref.watch(cuttingRepositoryProvider).watchAll(
        poNo: filters.poNo,
        from: filters.from,
        to: filters.to,
      );
});

final cuttingDetailProvider =
    FutureProvider.family<Cutting?, String>((ref, docId) async {
  return ref.watch(cuttingRepositoryProvider).getById(docId);
});

enum CuttingFormStatus { idle, loading, success, error }

class CuttingFormState {
  const CuttingFormState({
    required this.cutting,
    this.status = CuttingFormStatus.idle,
    this.errorMessage,
  });

  factory CuttingFormState.initial() {
    final now = DateTime.now();
    return CuttingFormState(
      cutting: Cutting(
        voucherNo: '',
        cuttingDate: now,
        factoryName: '',
        poNo: '',
        article: '',
        color: '',
        cuttingQuantity: 1,
        entryPerson: '',
        tagNo: '',
        company: '',
        project: '',
        poQuantity: 0,
        source: 'manual',
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  final Cutting cutting;
  final CuttingFormStatus status;
  final String? errorMessage;

  CuttingFormState copyWith({
    Cutting? cutting,
    CuttingFormStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CuttingFormState(
      cutting: cutting ?? this.cutting,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CuttingFormNotifier extends StateNotifier<CuttingFormState> {
  CuttingFormNotifier(this._repository) : super(CuttingFormState.initial());

  final CuttingRepository _repository;

  void setCutting(Cutting cutting) {
    state = state.copyWith(cutting: cutting, clearError: true);
  }

  void update({
    String? voucherNo,
    DateTime? cuttingDate,
    String? factoryName,
    String? poNo,
    String? article,
    String? color,
    int? cuttingQuantity,
    String? entryPerson,
    String? tagNo,
    String? company,
    String? project,
    int? poQuantity,
  }) {
    state = state.copyWith(
      cutting: state.cutting.copyWith(
        voucherNo: voucherNo ?? state.cutting.voucherNo,
        cuttingDate: cuttingDate ?? state.cutting.cuttingDate,
        factoryName: factoryName ?? state.cutting.factoryName,
        poNo: poNo ?? state.cutting.poNo,
        article: article ?? state.cutting.article,
        color: color ?? state.cutting.color,
        cuttingQuantity: cuttingQuantity ?? state.cutting.cuttingQuantity,
        entryPerson: entryPerson ?? state.cutting.entryPerson,
        tagNo: tagNo ?? state.cutting.tagNo,
        company: company ?? state.cutting.company,
        project: project ?? state.cutting.project,
        poQuantity: poQuantity ?? state.cutting.poQuantity,
      ),
      clearError: true,
    );
  }

  Future<bool> save() async {
    final cutting = state.cutting;
    if (cutting.voucherNo.trim().isEmpty ||
        cutting.poNo.trim().isEmpty ||
        cutting.article.trim().isEmpty ||
        cutting.color.trim().isEmpty ||
        cutting.cuttingQuantity <= 0) {
      state = state.copyWith(
        status: CuttingFormStatus.error,
        errorMessage: 'Please complete all required fields.',
      );
      return false;
    }

    state = state.copyWith(
      status: CuttingFormStatus.loading,
      clearError: true,
    );

    try {
      await _repository.create(cutting);
      state = state.copyWith(status: CuttingFormStatus.success);
      return true;
    } on Failure catch (e) {
      state = state.copyWith(
        status: CuttingFormStatus.error,
        errorMessage: e.message,
      );
      return false;
    }
  }
}

final cuttingFormProvider =
    StateNotifierProvider<CuttingFormNotifier, CuttingFormState>(
  (ref) => CuttingFormNotifier(ref.watch(cuttingRepositoryProvider)),
);

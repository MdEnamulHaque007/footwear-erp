import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../data/models/cutting_model.dart';
import '../../data/repositories/cutting_repository.dart';
import '../../domain/usecases/create_manual_cutting_use_case.dart';
import '../../../../data/repositories/master_lc_repository.dart';
import '../../../../data/repositories/po_repository.dart';

final cuttingRepositoryProvider = Provider<CuttingRepository>(
  (ref) => FirestoreCuttingRepository(),
);

final manualCuttingUseCaseProvider = Provider<CreateManualCuttingUseCase>((ref) {
  return CreateManualCuttingUseCase(
    cuttingRepository: ref.watch(cuttingRepositoryProvider),
    poRepository: PORepository(),
    masterLCRepository: MasterLCRepository(),
  );
});

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

class CuttingAccess {
  const CuttingAccess({
    required this.canEdit,
    required this.canDelete,
  });

  final bool canEdit;
  final bool canDelete;
}

final cuttingAccessProvider = FutureProvider<CuttingAccess>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const CuttingAccess(canEdit: false, canDelete: false);
  }

  final snapshot =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final data = snapshot.data() ?? <String, dynamic>{};
  final role = data['role']?.toString() ?? '';
  final permissions = data['permissions'];

  if (role == 'admin') {
    return const CuttingAccess(canEdit: true, canDelete: true);
  }

  final modulePermissions =
      permissions is Map ? permissions['cutting'] : null;
  final edit =
      modulePermissions is Map && modulePermissions['edit'] == true;

  return CuttingAccess(canEdit: edit, canDelete: false);
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
  CuttingFormNotifier(this._useCase) : super(CuttingFormState.initial());

  final CreateManualCuttingUseCase _useCase;

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

  Future<void> resolveFromPo() async {
    final cutting = state.cutting;
    if (cutting.poNo.trim().isEmpty ||
        cutting.article.trim().isEmpty ||
        cutting.color.trim().isEmpty) {
      return;
    }

    state = state.copyWith(
      status: CuttingFormStatus.loading,
      clearError: true,
    );

    final result = await _useCase.resolve(
      cuttingDate: cutting.cuttingDate,
      voucherNo: cutting.voucherNo,
      factoryName: cutting.factoryName,
      poNo: cutting.poNo,
      article: cutting.article,
      color: cutting.color,
      cuttingQuantity: cutting.cuttingQuantity,
      entryPerson: cutting.entryPerson,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: CuttingFormStatus.error,
        errorMessage: failure.message,
      ),
      (resolved) => state = state.copyWith(
        status: CuttingFormStatus.idle,
        cutting: cutting.copyWith(
          voucherNo: resolved.voucherNo,
          tagNo: resolved.tagNo,
          company: resolved.company,
          project: resolved.project,
          poQuantity: resolved.poQuantity,
        ),
        clearError: true,
      ),
    );
  }

  Future<bool> save() async {
    final cutting = state.cutting;
    state = state.copyWith(
      status: CuttingFormStatus.loading,
      clearError: true,
    );

    final result = await _useCase.create(
      cuttingDate: cutting.cuttingDate,
      voucherNo: cutting.voucherNo,
      factoryName: cutting.factoryName,
      poNo: cutting.poNo,
      article: cutting.article,
      color: cutting.color,
      cuttingQuantity: cutting.cuttingQuantity,
      entryPerson: cutting.entryPerson,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: CuttingFormStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(status: CuttingFormStatus.success);
        return true;
      },
    );
  }
}

final cuttingFormProvider =
    StateNotifierProvider<CuttingFormNotifier, CuttingFormState>(
  (ref) => CuttingFormNotifier(
        ref.watch(manualCuttingUseCaseProvider),
      ),
);
